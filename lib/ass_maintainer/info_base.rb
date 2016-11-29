require 'ass_maintainer/info_base/version'

module AssMaintainer
  class InfoBase
    extend AssLauncher::Api
    require 'ass_maintainer/info_base/config'
    require 'ass_maintainer/info_base/interfaces'
    require 'ass_maintainer/info_base/file_ib'
    require 'ass_maintainer/info_base/server_ib'

    # :nodoc:
    class MethodDenied < StandardError
      def initialize(m)
        super "Infobase is read_only. Method #{m} denied!"
      end
    end

    # @abstract
    class AbstractCfg
      attr_reader :infobase
      # @param [InfoBase]
      def initialize(infobase)
        @infobase = infobase
      end
    end

    # Object for manipuate whith infobase configuration
    class Cfg < AbstractCfg
      # Dump configuration to +XML+ files
      # @param path [String]
      def dump_xml(path)
        fail 'FIXME'
      end

      # Dump configuration to +.cf+ file
      # @param path [String]
      def dump(path)
        fail 'FIXME'
      end

      # Load configuration from +XML+ files
      # @param path [String]
      def load_xml(path)
        fail MethodDenied, :load_xml if infobase.read_only?
        fail 'FIXME'
      end

      # Load configuration from +.cf+ file
      # @param path [String]
      def load(path)
        fail MethodDenied, :load_cf if infobase.read_only?
        fail 'FIXME'
      end
    end

    # Object for manipuate whith database configuration
    class DbCfg < AbstractCfg
      # Update database configuration from infobase
      # configuration
      def update
        fail MethodDenied, :update if infobase.read_only?
        fail 'FIXME'
      end

      # Dump configuration to +.cf+ file
      # @param path [String]
      def dump(path)
        fail 'FIXME'
      end
    end

    class DefaultMaker
      include Interfaces::IbMaker
      def entry_point
        cs = infobase.make_connection_string
        cmd = infobase.thick.command(:createinfobase) do
          connection_string cs
          _L 'en'
        end
        cmd.run.wait.result.verify!
      end
    end

    OPTIONS = {
      maker: nil,
      destroyer: nil,
      platform_require: config.platform_require,
      before_make: ->(ib){},
      after_make: ->(ib){},
      before_rm: ->(ib){},
      after_rm: ->(ib){}
    }

    OPTIONS.each_key do |key|
      next if key == :maker || key == :destroyer
      define_method key do
        options[key]
      end
    end

    attr_reader :name, :connection_string, :options, :read_only?
    def initialize(name, connection_string, read_only = true, **options)
      @name = name
      @connection_string = self.class.cs(connection_string.to_s)
      @read_only = read_only
      @options = OPTIONS.merge(options)
      if connection_string.is? :file
        extend FileIb
      elsif connection_string.is? :server
        extend ServerIb
      else
        fail ArgumentError
      end
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
    # @raise [MethodDenied] if infobase {read_only?}
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
    # @raise [MethodDenied] if infobase {read_only?}
    def rm_infobase!
      fail MethodDenied, :rm_infobase! if read_only?
      befor_rm.call(self)
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
    def thick_client
      self.class.thickis(platform_require).last ||\
        fail("Platform 1C #{platform_require} not found")
    end

    # @return [AssLauncher::Enterprise::BinaryWrapper::ThinClient]
    def thin_client
      self.class.thin(platform_require).last ||\
        fail("Platform 1C #{platform_require} not found")
    end

    def fail_if_not_exists
      fail 'Infobase not exists' unless exists?
    end

    # Dump infobase to +.dt+ file
    def dump(path)
      fail_if_not_exists
      cs = connection_string
      cmd = thick.command(:designer) do
        connection_string cs
        dumpIB path
      end
      cmd.run.wait.result.verify!
    end

    # Restore infobase from +.dt+ file
    # @raise [MethodDenied] if {#read_only?}
    def restore!(path)
      fail MethodDenied, :restore! if read_only?
      fail_if_not_exists
      fail 'FIXME'
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

    # Returns array of infobase sessions
    # @return [Array <Session>]
    def sessions
      fail NotImplementsError
    end

    # Lock infobase. It work for server infobase only.
    # For file infobase it do nothing
    def lock
      fail NotImplementsError
    end

    # Unlock infobase which {#locked_we?}.
    # It work for server infobase only.
    # For file infobase it do nothing
    def unlock
      fail NotImplementsError
    end

    # Unlock infobase.
    # It work for server infobase only.
    # For file infobase it do nothing
    def unlock!(uc)
      fail NotImplementsError
    end

    # Lock infobase. It work for server infobase only.
    # For file infobase it return false
    def locked?
      fail NotImplementsError
    end

    # True if infobase locked this
    # For file infobase it return false
    def locked_we?
      fail NotImplementsError
    end
  end
end
