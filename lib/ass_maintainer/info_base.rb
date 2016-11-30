require 'ass_maintainer/info_base/version'
require 'ass_launcher'

module AssMaintainer
  # rubocop:disable Metrics/ClassLength

  # Class for manipulate with 1C:Enterprise application instance aka
  # +information base+ or +infobase+
  #
  # Instances of this class have dinamicly generated interfaece
  #
  # 1C:Enterprise application may be deployed as file (aka file infobase) or
  # on a 1C:Enterprise server (aka server infobase). In the {#initialize}
  # instance of this class will be extended suitable module:
  # - server infobase instance will be extend module {ServerIb}
  # - file infobase instance will be exten module {FileIb}
  #
  # Both instance type inherits methods from {Interfaces::InfoBaseWrapper}
  #
  # All instances get methods wrappers for access to {#options} see
  # {.build_options_wrapper}
  class InfoBase
    extend AssLauncher::Api
    require 'ass_maintainer/info_base/config'
    require 'ass_maintainer/info_base/interfaces'
    require 'ass_maintainer/info_base/file_ib'
    require 'ass_maintainer/info_base/server_ib'

    # :nodoc:
    class MethodDenied < StandardError
      def initialize(m)
        super "Infobase is read only. Method #{m} denied!"
      end
    end

    # @abstract
    class AbstractCfg
      attr_reader :infobase
      # @param infobase [InfoBase]
      def initialize(infobase)
        @infobase = infobase
      end
    end

    # Object for manipuate whith infobase configuration
    class Cfg < AbstractCfg
      # Dump configuration to +XML+ files
      # @param path [String]
      # @return [String] path
      def dump_xml(path)
        infobase.designer do
          dumpConfigToFiles path
        end.run.wait.result.verify!
        path
      end

      # Dump configuration to +.cf+ file
      # @param path [String]
      # @return [String] path
      def dump(path)
        infobase.designer do
          dumpCfg path
        end.run.wait.result.verify!
        path
      end

      # Load configuration from +XML+ files
      # @param path [String]
      # @return [String] path
      def load_xml(path)
        fail MethodDenied, :load_xml if infobase.read_only?
        infobase.designer do
          loadConfigFromFiles path
        end.run.wait.result.verify!
        path
      end

      # Load configuration from +.cf+ file
      # @param path [String]
      # @return [String] path
      def load(path)
        fail MethodDenied, :load_cf if infobase.read_only?
        infobase.designer do
          loadCfg path
        end.run.wait.result.verify!
        path
      end
    end

    # Object for manipuate whith database configuration
    class DbCfg < AbstractCfg
      # Update database configuration from infobase
      # configuration
      def update
        fail MethodDenied, :update if infobase.read_only?
        infobase.designer do
          updateDBCfg do
            warningsAsErrors
          end
        end.run.wait.result.verify!
      end

      # Dump configuration to +.cf+ file
      # @param path [String]
      # @return [String] path
      def dump(path)
        infobase.designer do
          dumpDBCfg path
        end.run.wait.result.verify!
        path
      end
    end

    # Default infobase maker
    class DefaultMaker
      include Interfaces::IbMaker
      # :hodoc:
      def entry_point
        infobase.thick
          .command(:createinfobase,
                   infobase.connection_string.createinfobase_args +
                   infobase.common_args)
          .run.wait.result.verify!
      end
    end

    # Deafult port for connect to 1C:Enterprise serever agent
    DEFAULT_SAGENT_PORT = '1540'

    # Hooks before and after make and remove infobase. Hooks may be passed as
    # options or seted later see {#add_hook}
    HOOKS = {
      before_make: ->(ib) {},
      after_make: ->(ib) {},
      before_rm: ->(ib) {},
      after_rm: ->(ib) {}
    }

    # On default for make and remove infobase uses {DefaultMaker} and
    # {FileIb::FileBaseDestroyer} or {ServerIb::ServerBaseDestroyer}
    # but we can pass custom maker and destroyer as {#options}.
    # Maker and destroyer must implements {Interfaces::IbMaker} and
    # {Interfaces::IbDestroyer}
    WORKERS = {
      maker: nil,
      destroyer: nil
    }

    # - +:latform_require+ Required 1C:Enterprise version
    # - +:agent_host+ Host name of 1C:Enterprise server agent
    # - +:agent_port+ TCP port of 1C:Enterprise server agent on
    #   default {DEFAULT_SAGENT_PORT}
    # - +:agent_usr+ Admin for 1C:Enterprise server agent
    # - +:agent_pwd+ Admin password for 1C:Enterprise server agent
    # - +:laster_usr+ Admin for 1C:Enterprise claster.
    #   See {ServerIb#claster_usr}
    # - +:laster_pwd+ Pasword Admin for 1C:Enterprise claster.
    #   See {ServerIb#claster_pwd}
    # - +:nlock_code+ Code for connect to locked infobase aka "/UC" parameter
    ARGUMENTS = {
      platform_require: nil,
      sagent_host: nil,
      sagent_port: nil,
      sagent_usr: nil,
      sagent_pwd: nil,
      claster_usr: nil,
      claster_pwd: nil,
      unlock_code: nil
    }

    OPTIONS = (ARGUMENTS.merge HOOKS).merge WORKERS

    # Dinamicaly builds of options wrappers
    def self.build_options_wrapper
      OPTIONS.each_key do |key|
        next if WORKERS.keys.include? key
        define_method key do
          options[key]
        end

        next if HOOKS.keys.include? key
        define_method "#{key}=".to_sym do |arg|
          options[key] = arg
        end
      end
    end

    build_options_wrapper

    # see {#initialize} +name+
    attr_reader :name
    # see {#initialize} +connection_string+
    attr_reader :connection_string
    # see {#initialize} +options+
    attr_reader :options
    # InfoBase is read only
    # destructive methods will be fail with {MethodDenied} error
    attr_reader :read_only
    alias_method :read_only?, :read_only

    # @param name [String] name of infobase
    # @param connection_string [String AssLauncher::Support::ConnectionString]
    # @param read_only [true false] infobse is read only or not
    # @param options [Hash] see {OPTIONS}
    def initialize(name, connection_string, read_only = true, **options)
      @name = name
      @connection_string = self.class.cs(connection_string.to_s)
      @read_only = read_only
      @options = OPTIONS.merge(options)
      case self.connection_string.is
      when :file then extend FileIb
      when :server then extend ServerIb
      else fail ArgumentError
      end
      yield self if block_given?
    end

    # Add hook. In all hook whill be passed +self+
    # @raise [ArgumentError] if invalid hook name or not block given
    # @param hook [Symbol] hook name
    def add_hook(hook, &block)
      fail ArgumentError, "Invalid hook `#{hook}'" unless\
        HOOKS.keys.include? hook
      fail ArgumentError, 'Block require' unless block_given?
      options[hook] = block
    end

    # Requrement 1C version
    # @return [String]
    def platform_require
      options[:platform_require] || self.class.config.platform_require
    end

    # Rebuild infobse first call {#rm!} second call {#make}
    # @raise (see #rm!)
    def rebuild!(sure = :no)
      rm! sure
      make
    end

    # (see #make_infobase!)
    def make
      make_infobase! unless exists?
      self
    end

    # Make new empty infobase
    # wrpped in +before_make+ and +after_make+ hooks
    # @raise [MethodDenied] if infobase {#read_only?}
    def make_infobase!
      fail MethodDenied, :make_infobase! if read_only?
      before_make.call(self)
      maker.execute(self)
      after_make.call(self)
      self
    end
    private :make_infobase!

    # (see #rm_infobase!)
    def rm!(sure = :no)
      fail 'If you are sure pass :yes value' unless sure == :yes
      return unless exists?
      rm_infobase!
      nil
    end

    # Remove infobase
    # wrpped in +before_rm+ and +after_rm+ hooks
    # @raise [MethodDenied] if infobase {#read_only?}
    def rm_infobase!
      fail MethodDenied, :rm_infobase! if read_only?
      before_rm.call(self)
      destroyer.execute(self)
      after_rm.call(self)
    end
    private :rm_infobase!

    # Returns type of infobase
    # @return [Symbol] +:file+ or +:server+
    def is
      connection_string.is
    end

    # Check type of infobase
    # @param type [Symbol] +:file+ or +:server+
    def is?(type)
      connection_string.is?(type)
    end

    # Set user name
    def usr=(user_name)
      connection_string.usr = user_name
    end

    # User name
    # @return [String]
    def usr
      connection_string.usr
    end

    # Set locale
    # @param l [String] locale code +en+, +ru+ etc
    def locale=(l)
      connection_string.locale = l
    end

    # Get locale
    # @return [String]
    def locale
      connection_string.locale
    end

    # Set user password
    def pwd=(password)
      connection_string.pwd = password
    end

    # User password
    # @return [String]
    def pwd
      connection_string.pwd
    end

    # @return [AssLauncher::Enterprise::BinaryWrapper::ThickClient]
    def thick
      self.class.thicks(platform_require).last ||
        fail("Platform 1C #{platform_require} not found")
    end

    # @return [AssLauncher::Enterprise::BinaryWrapper::ThinClient]
    def thin
      self.class.thins(platform_require).last ||
        fail("Platform 1C #{platform_require} not found")
    end

    # Get ole connector specified in +type+ parameter
    # @param type [Symbol] see +AssLauncher::Api#ole+
    def ole(type)
      self.class.ole(type, ole_requirement)
    end

    def ole_requirement
      "= #{thick.version}"
    end
    private :ole_requirement

    def fail_if_not_exists
      fail 'Infobase not exists' unless exists?
    end
    private :fail_if_not_exists

    # Build command for run designer
    # block will be passed to arguments builder
    # @return [AssLauncher::Support::Shell::Command]
    def designer(&block)
      fail_if_not_exists
      thick.command(:designer, connection_string.to_args + common_args, &block)
    end

    # Build command for run enterprise
    # block will be passed to arguments builder
    # @param client [Symbol] +:thin+ or +thick+ client
    # @return [AssLauncher::Support::Shell::Command]
    def enterprise(client, &block)
      fail_if_not_exists
      case client
      when :thin then
        thin.command(connection_string.to_args + common_args, &block)
      when :thick then
        thick.command(:enterprise, connection_string.to_args + common_args,
                      &block)
      else
        fail ArgumentError, "Invalid clent #{client}"
      end
    end

    # Common arguments for all commands
    def common_args
      r = []
      r += ['/L', locale] if locale
      r += ['/UC', unlock_code] if unlock_code
      r
    end

    # Dump infobase to +.dt+ file
    def dump(path)
      designer do
        dumpIB path
      end.run.wait.result.verify!
      path
    end

    # Restore infobase from +.dt+ file
    # @raise [MethodDenied] if {#read_only?}
    def restore!(path)
      fail MethodDenied, :restore! if read_only?
      designer do
        restoreIB path
      end.run.wait.result.verify!
      path
    end

    # Returns instance for manipuate with
    # InfoBase database. If infobase not
    # exists returns nil
    # @return [Dbase nil]
    def db_cfg
      @db_cfg ||= DbCfg.new(self) if exists?
    end

    # Returns instance for manipuate with
    # databse configuration. If infobase not
    # exists returns nil
    # @return [Cfg nil]
    def cfg
      @cfg ||= Cfg.new(self) if exists?
    end

    extend Forwardable
    def_delegators :infobase_wrapper,
                   *Interfaces::InfoBaseWrapper.instance_methods
  end
  # rubocop:enable Metrics/ClassLength
end
