module AssMaintainer
  class InfoBase
    module ServerIb
      require 'ass_ole'
      module EnterpriseServers
        # Helpers
        module Support
          # Redirect +method_missing+ to +ole+ object
          module SendToOle
            def method_missing(m, *args)
              ole.send m, *args
            end
          end
        end

        # Mixins for serever connection describers {Cluster} {ServerAgent}
        module ServerConnection
          # Server user name
          # See {#initialize} +user+ argument.
          # @return [String]
          attr_accessor :user

          # Server user password
          # See {#initialize} +password+ argument.
          # @return [String]
          attr_accessor :password

          # Host name
          attr_accessor :host

          # TCP port
          attr_accessor :port

          # @param host_port [String] string like a +host_name:port_number+
          # @param user [String] server user name
          # @param password [String] serever user password
          def initialize(host_port, user = nil, password = nil)
            fail ArgumentError, 'Host name require' if host_port.to_s.empty?
            @raw_host_port = host_port
            @host = parse_host
            @port = parse_port || default_port
            @user = user
            @password = password
          end

          # String like a +host_name:port_number+.
          # @return [String]
          def host_port
            "#{host}:#{port}"
          end

          def parse_port
            p = @raw_host_port.split(':')[1].to_s.strip
            return p unless p.empty?
          end
          private :parse_port

          def parse_host
            p = @raw_host_port.split(':')[0].to_s.strip
            fail ArgumentError, "Invalid host_name for `#{@raw_host_port}'" if\
              p.empty?
            p
          end
          private :parse_host

          def default_port
            fail 'Abstract method'
          end

          # Return +true+ if TCP port available on server
          def ping?
            tcp_ping.ping?
          end

          require 'net/ping/tcp'
          # @return [Net::Ping::TCP] instance
          def tcp_ping
            @tcp_ping ||= Net::Ping::TCP.new(host, port)
          end

          def eql?(other)
            host.upcase == other.host.upcase && port == other.port
          end
          alias_method :==, :eql?
        end

        # @api private
        # Object descrbed 1C server agent connection.
        # @example
        #   # Get 1C:Eneterprise serever agent connection object and connect
        #   # to net service
        #   sagent = ServerAgent.new('localhost:1540', 'admin', 'password')
        #     .connect('~> 8.3.8.0')
        #
        #   # Working with serever agent connection
        #   sagent.ConnectionString #=> "tcp://localhost:1540"
        #   cl = sagent.cluster_find 'localhost', '1542'
        #
        #   # Close connection
        #   sagent.disconnect
        #
        module ServerAgent
          include ServerConnection

          # Make new object of anonymous class which included this module.
          def self.new(host_port, user, password)
            Class.new do
              include ServerAgent
            end.new host_port, user, password
          end

          # Make new [AssOle::Runtimes::Claster::Agent] module for access
          # to [AssLauncher::Enterprise::Ole::AgentConnection]
          # @return [Module]
          def self.runtime_new
            Module.new do
              is_ole_runtime :agent
            end
          end

          # @return [String] wrapper for {InfoBase::DEFAULT_SAGENT_PORT}
          def default_port
            InfoBase::DEFAULT_SAGENT_PORT
          end

          # Connect to 1C:Eneterprise server via OLE
          # @note while connecting in instance class will be included
          # {.runtime_new} module
          # @param platform_require [String Gem::Requirement]
          # 1C:Eneterprise version required
          # @return +self+
          def connect(platform_require)
            runtime_run platform_require unless connected?
            begin
              authenticate unless authenticate?
            rescue
              runtime_stop
              raise
            end
            self
          end

          # Close connection with 1C:Enterprise server
          def disconnect
            runtime_stop
          end

          def runtime_stop
            ole_runtime_get.stop if respond_to? :ole_runtime_get
          end
          private :runtime_stop

          # Include and run {.runtime_new} runtime
          def runtime_run(platform_require)
            self.class.like_ole_runtime ServerAgent.runtime_new unless\
              respond_to? :ole_runtime_get
            ole_runtime_get.run host_port, platform_require
          end
          private :runtime_run

          # Authenticate {#user}
          # @raise if not connected
          def authenticate
            AuthenticateAgent(user, password.to_s) if\
              connected? && !authenticate?
          end

          # True if connected
          def connected?
            respond_to?(:ole_runtime_get) && ole_runtime_get.runned?
          end

          # True if #{user} authenticate
          def authenticate?
            return false unless connected?
            begin
              ole_connector.GetAgentAdmins
            rescue
              return false
            end
            true
          end

          # @return [nil WIN32OLE] +IClusterInfo+ ole object
          # @raise if not connected
          def cluster_find(host, port)
            GetClusters().find do |cl|
              cl.HostName.upcase == host.upcase && cl.MainPort == port.to_i
            end
          end
        end

        # @api private
        # Object descrbed 1C cluster
        class Cluster
          # Deafult 1C:Enterprise cluster TCP port
          DEF_PORT = '1541'

          include ServerConnection
          include Support::SendToOle

          # @return [String] {DEF_PORT}
          def default_port
            DEF_PORT
          end

          # Attache cluster into serever agent
          # @param agent [ServerAgent]
          # @raise (see #authenticate)
          def attach(agent)
            @sagent = agent unless @sagent
            ole_set unless @ole
            authenticate
          end

          # @return [ServerAgent] which cluster attached
          # @raise [RuntimeError] unless cluster attached
          def sagent
            fail 'Cluster must be attachet to ServerAgent' unless @sagent
            @sagent
          end

          # @return +IClusterInfo+ ole object
          # @raise [RuntimeError] if cluster not found on {#sagent} server
          def ole
            fail ArgumentError, "Cluster `#{host_port}'"\
              " not found on server `#{sagent.host_port}'" unless @ole
            @ole
          end

          # True if cluster attached into {#sagent} serever
          def attached?
            !@sagent.nil? && !@ole.nil?
          end

          # Authenticate cluster user
          # @raise (see #ole)
          def authenticate
            sagent.Authenticate(ole, user, password)
            self
          end

          def ole_set
            @ole = sagent.cluster_find(host, port)
            ole
          end
          private :ole_set

          # @return [Array<WIN32OLE>] aray of +IInfoBaseShort+ ole objects
          # registred in cluster
          # @raise (see #ole)
          # @raise (see #sagent)
          def infobases
            sagent.GetInfoBases(ole)
          end

          # Searching infobase in {#infobases} array
          # @param ib_name [String] infobase name
          # @return [WIN32OLE] +IInfoBaseShort+ ole object
          # @raise (see #infobases)
          def infobase_find(ib_name)
            infobases.find do |ib|
              ib.Name.upcase == ib_name.upcase
            end
          end

          # True if infobase registred in cluster
          # @param ib_name [String] infobase name
          # @raise (see #infobase_find)
          def infobase_include?(ib_name)
            !infobase_find(ib_name).nil?
          end

          # @return [nil Array<Wrappers::Session>] sessions for infobase
          # runned in cluster. +nil+ if infobase +ib_name+ not registred in
          # cluster.
          # @param ib_name [String] infobase name
          # @raise (see #sagent)
          def infobase_sessions(ib_name)
            ib = infobase_find(ib_name)
            return unless ib
            sagent.GetInfoBaseSessions(ole, ib).map do |s|
              Wrappers::Session.new(s, self)
            end
          end

          # FIXME
          def wprocesses
            sagent.GetWorkingProcesses(ole).map do |wpi|
              Wrappers::WorkingProcessInfo.new(wpi, self)
            end
          end

          # FIXME
          def infobase_drop(ib_ref, mode = ServerBaseDestroyer::DEF_MODE)
            return unless infobase_include? ib_ref
            fail 'FIXME'
            true
          end
        end

        # Wrappers for 1C OLE objects
        module Wrappers
          # Wrapper for 1C:Enterprise +IWorkingProcessInfo+ ole object
          module WorkingProcessInfo
            include Support::SendToOle
            attr_reader :ole, :cluster, :sagent
            def initialize(ole, cluster)
              @ole, @cluster, @sagent = ole, cluster, cluster.sagent
            end
          end

          # Wrapper for 1C:Enterprise +ISessionInfo+ ole object
          class Session
            include Support::SendToOle

            # @api private
            # @return +ISessionInfo+ ole object
            attr_reader :ole

            # @api private
            # @return [EnterpriseServers::Cluster] cluster where session
            # registred
            attr_reader :cluster

            # @api private
            # @return [EnterpriseServers::ServerAgent] 1C server where session
            # registred
            attr_reader :sagent

            # @api private
            def initialize(ole, cluster)
              @ole, @cluster, @sagent = ole, cluster, cluster.sagent
            end

            # Terminate session
            def terminate
              sagent.TerminateSession(cluster.ole, ole)
            rescue WIN32OLERuntimeError
            end
          end
        end
      end

      # @api private
      # Wrapper for manipulate
      # with real information base deployed in 1C:Enterprise server
      # ower the 1C Ole classes
      class InfoBaseWrapper
        include Interfaces::InfoBaseWrapper
        attr_accessor :infobase
        alias_method :ib, :infobase

        def initialize(infobase)
          self.infobase = infobase
        end

        # @return [EnterpriseServers::ServerAgent]
        def sagent_get
          EnterpriseServers::ServerAgent
            .new "#{ib.sagent_host || ib.clusters[0].host}:#{ib.sagent_port}",
                 ib.sagent_usr,
                 ib.sagent_pwd
        end
        private :sagent_get

        # @return [AssLauncher::Enterprise::Ole::AgentConnection]
        def sagent
          @sagent ||= sagent_get.connect(infobase.platform_require)
        end

        # @return [Array<EnterpriseServers::Cluster>] clusters defined in
        # +#infobase.clusters+ attached into {#sagent}
        def clusters
          infobase.clusters.select do |cl|
            cl.attach(sagent).infobase_include? ib_ref
          end
        end

        # Helper
        def ib_ref
          ib.connection_string.ref
        end
        private :ib_ref

        # @return [Array<EnterpriseServers::Wrappers::Session>] infobase
        # sessions
        def sessions
          return [] unless exists?
          clusters.map do |cl|
            cl.infobase_sessions(ib_ref)
          end.flatten
        end

        # True if infobase exists
        def exists?
          clusters.size > 0
        end

        # True if infobse locked
        def locked?
          fail "FIXME"
        end
      end
    end
  end
end
