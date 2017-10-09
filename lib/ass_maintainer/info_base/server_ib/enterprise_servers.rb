module AssMaintainer
  class InfoBase
    module ServerIb
      require 'ass_ole'
      module EnterpriseServers
        require 'ass_maintainer/info_base/server_ib/enterprise_servers/support'
        require 'ass_maintainer/info_base/server_ib/enterprise_servers/server_agent'
        require 'ass_maintainer/info_base/server_ib/enterprise_servers/cluster'
        require 'ass_maintainer/info_base/server_ib/enterprise_servers/wp_connection'

        # @api private
        # Wrappers for 1C OLE objects
        module Wrappers
          # @api private
          # Wrapper for 1C:Enterprise +IWorkingProcessInfo+ ole object
          class WorkingProcessInfo
            include Support::SendToOle
            attr_reader :ole, :cluster, :sagent, :connection
            def initialize(ole, cluster)
              @ole, @cluster, @sagent = ole, cluster, cluster.sagent
            end

            def connect(infobase_wrapper)
              WpConnection.new(self).connect(infobase_wrapper)
            end

            # Return +true+ if TCP port available on server
            def ping?
              tcp_ping.ping?
            end

            require 'net/ping/tcp'
            # @return [Net::Ping::TCP] instance
            def tcp_ping
              @tcp_ping ||= Net::Ping::TCP.new(hostName, mainPort)
            end
          end

          # @api private
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

            # @return [InfoBase::Session]
            # @param infobase [InfoBase] instance
            def to_session(infobase)
              InfoBase::Session
                .new SessionId(), AppId(), Host(), UserName(), infobase
            end
          end
        end
      end
    end
  end
end
