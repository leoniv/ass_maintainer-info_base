module AssMaintainer
  class InfoBase
    module ServerIb
      module EnterpriseServers
        # @api private
        # Object descrbed 1C server agent connection.
        # @example
        #   # Get 1C:Eneterprise server agent connection object and connect
        #   # to net service
        #   sagent = ServerAgent.new('localhost:1540', 'admin', 'password')
        #     .connect('~> 8.3.8.0')
        #
        #   # Working with server agent connection
        #   sagent.ConnectionString #=> "tcp://localhost:1540"
        #   cl = sagent.cluster_find 'localhost', '1542'
        #
        #   # Close connection
        #   sagent.disconnect
        #
        module ServerAgent
          include Support::ServerConnection
          include Support::OleRuntime
          include Support::Reconnect

          # Make new object of anonymous class which included this module.
          def self.new(host_port, user, password)
            Class.new do
              include ServerAgent
            end.new host_port, user, password
          end

          # @return [String] wrapper for {InfoBase::DEFAULT_SAGENT_PORT}
          def default_port
            InfoBase::DEFAULT_SAGENT_PORT
          end

          def runtime_type
            :agent
          end

          # Connect to 1C:Eneterprise server via OLE
          # @note while connecting in instance class will be included
          # {.runtime_new} module
          # @param platform_require [String Gem::Requirement]
          # 1C:Eneterprise version required
          # @return +self+
          def connect(platform_require)
            _connect(host_port, platform_require)
          end

          # Authenticate {#user}
          # @raise if not connected
          def authenticate
            AuthenticateAgent(user.to_s, password.to_s) if\
              connected? && !authenticate?
          end

          # True if #{user} authenticate
          def authenticate?
            return false unless connected?
            begin
              ole_connector.GetAgentAdmins
            rescue WIN32OLERuntimeError
              return false
            end
            true
          end

          # @return [nil WIN32OLE] +IClusterInfo+ ole object
          # @raise if not connected
          def cluster_find(host, port)
            reconnect
            GetClusters().find do |cl|
              cl.HostName.upcase == host.upcase && cl.MainPort == port.to_i
            end
          end

          def platform_require
            return unless connected?
            ole_connector.send(:__ole_binary__).requirement.to_s
          end

          def _reconnect_required?
            getClusters.empty?
          end
          private :_reconnect_required?
        end
      end
    end
  end
end
