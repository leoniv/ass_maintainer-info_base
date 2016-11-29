module AssMaintainer
  class InfoBase
    module ServerIb
      module EnrepriseServers
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
    end
  end
end
