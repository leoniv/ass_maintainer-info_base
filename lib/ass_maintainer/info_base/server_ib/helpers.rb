module AssMaintainer
  class InfoBase
    module ServerIb
      require 'ass_ole'
      module EnterpriseServers
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
        end

        # Object descrbed 1C server agent connection
        module ServerAgent
          include ServerConnection

          def self.new(host_port, user, password)
            Class.new do
              include ServerAgent
            end.new host_port, user, password
          end

          def self.runtime_new
            Module.new do
              is_ole_runtime :agent
            end
          end

          def default_port
            InfoBase::DEFAULT_SAGENT_PORT
          end

          # Connect to 1C:Eneterprise server via OLE
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

          def runtime_run(platform_require)
            self.class.like_ole_runtime ServerAgent.runtime_new unless\
              respond_to? :ole_runtime_get
            ole_runtime_get.run host_port, platform_require
          end
          private :runtime_run

          def authenticate
            AuthenticateAgent(user, password.to_s) if\
              connected? && !authenticate?
          end
          private :authenticate

          def connected?
            respond_to?(:ole_runtime_get) && ole_runtime_get.runned?
          end

          def authenticate?
            return false unless connected?
            begin
              ole_connector.GetAgentAdmins
            rescue
              return false
            end
            true
          end

          def cluster_find(host, port)
            GetClusters().find do |cl|
              cl.HostName.upcase == host.upcase && cl.MainPort == port.to_i
            end
          end
        end

        # Object descrbed 1C cluster
        class Cluster
          DEF_PORT = '1541'
          include ServerConnection

          def default_port
            DEF_PORT
          end

          attr_reader :sagent
          attr_reader :ole

          def method_missing(m, *args)
            ole.send m, *args
          end

          def attach(agent)
            @sagent = agent unless sagent
            ole_set unless ole
            authenticate
          end

          def attached?
            !sagent.nil? && !ole.nil?
          end

          def authenticate
            fail 'Cluster must be attachet to ServerAgent' unless attached?
            sagent.Authenticate(ole, user, password)
            self
          end

          def ole_set
            @ole = sagent.cluster_find(host, port)
            fail ArgumentError, "Cluster `#{host_port}'"\
              " not found on server `#{sagent.host_port}'" unless @ole
          end
          private :ole_set

          def infobases
            sagent.GetInfoBases(ole)
          end

          def infobase_find(ib_ref)
            infobases.find do |ib|
              ib.Name.upcase == ib_ref.upcase
            end
          end

          def infobase_include?(ib_ref)
            !infobase_find(ib_ref).nil?
          end
        end
      end

      # Wrapper for manipulate
      # with real information base deployed in 1C:Enterprise server
      # ower the 1C Ole classes
      class InfoBaseWrapper
        include Interfaces::InfoBaseWrapper
        attr_accessor :infobase
        alias_method :ib, :infobase

        # @api private
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

        def main_cluster
          infobase.clusters.find do |cl|
            cl.attach(sagent).infobase_include? ib.connection_string.ref
          end
        end

        # True if infobase exists
        def exists?
          !main_cluster.nil?
        end
      end
    end
  end
end
