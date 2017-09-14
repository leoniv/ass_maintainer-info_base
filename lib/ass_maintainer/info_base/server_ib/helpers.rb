module AssMaintainer
  class InfoBase
    module ServerIb
      module EnterpriseServers
        # Mixins for serever connection describers {Cluster} {ServerAgent}
        module ServerConnection
          # Server user name
          # See {#initialize} +user+ argument.
          # @return [String]
          attr_reader :user

          # Server user password
          # See {#initialize} +password+ argument.
          # @return [String]
          attr_reader :password

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
        class ServerAgent
          include ServerConnection

          def default_port
            InfoBase::DEFAULT_SAGENT_PORT
          end

          def to_cluster
            Cluster.new(host, user, password)
          end

          # @param ib [InfoBase] serever infobase
          def connect(ole)
            ole.__open__(host_port)
            ole.AuthenticateAgent(user, password) if user
            ole
          end
        end

        # Object descrbed 1C cluster manager connection
        class Cluster
          DEF_PORT = '1541'
          include ServerConnection

          def default_port
            DEF_PORT
          end

          def to_server_agent
            ServerAgent.new(host, user, password)
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

        # @return (see #server_agent)
        def server_agent
          EnterpriseServers::ServerAgent
            .new "#{ib.sagent_host || ib.clusters[0].host}:#{ib.sagent_port}",
                 ib.sagent_usr,
                 ib.sagent_pwd
        end

        # @return [AssLauncher::Enterprise::Ole::AgentConnection]
        def sagent
          @sagent ||= server_agent.connect(infobase.ole(:sagent))
        end

        # True if infobase exists
        def exists?
          fail NotImplementedError
        end
      end
    end
  end
end
