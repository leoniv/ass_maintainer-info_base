module AssMaintainer
  class InfoBase
    module ServerIb
      module EnterpriseServers
        # Mixins for serever connection describers {Claster} {ServerAgent}
        module ServerConnection
          attr_reader :host_port, :user, :password
          def initialize(host_port, user, password)
            fail ArgumentError, 'Host name require' if host_port.to_s.empty?
            @host_port = host_port.to_s
            @user = user
            @password = password
          end
        end

        # Object descrbed 1C server agent connection
        class ServerAgent
          include ServerConnection
        end

        # Object descrbed 1C claster connection
        class Claster
          include ServerConnection
          def self.from_cs(cs)
            new cs.srvr, cs.susr, cs.spwd
          end
        end
      end

      # Wrapper for manipulate
      # with real information base deployed in 1C:Enterprise server
      # ower the 1C Ole classes
      class InfoBaseWrapper
        include Interfaces::InfoBaseWrapper
        attr_accessor :infobase, :server_agent, :claster
        # @api private
        def initialize(infobase, server_agent, claster)
          self.infobase = infobase
          self.server_agent = server_agent
          self.claster = claster
        end

        # True if infobase exists
        def exists?
          fail NotImplementedError
        end
      end
    end
  end
end
