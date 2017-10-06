module AssMaintainer
  class InfoBase
    module ServerIb
      module EnterpriseServers
        # @api private
        # Object descrbed 1C cluster
        class Cluster
          # Deafult 1C:Enterprise cluster TCP port
          DEF_PORT = '1541'

          include Support::ServerConnection
          include Support::SendToOle
          include Support::InfoBaseFind

          # @return [String] {DEF_PORT}
          def default_port
            DEF_PORT
          end

          # Attache cluster into serever agent
          # @param agent [ServerAgent]
          # @raise (see #authenticate)
          def attach(agent)
            @sagent = agent unless @sagent
            ole_set
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
            sagent.Authenticate(ole, user.to_s, password.to_s)
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

          # All Working processes in cluster
          # @return [Array<Wrappers::WorkingProcessInfo]
          def wprocesses
            sagent.GetWorkingProcesses(ole).map do |wpi|
              Wrappers::WorkingProcessInfo.new(wpi, self)
            end
          end

          # Connect to working process
          # @return [WpConnection] object for comunication with 1C Working
          #   process
          def wp_connection(infobase_wrapper)
            if !@wp_connection.nil? && !@wp_connection.ping?
              @wp_connection = nil
            end
            @wp_connection ||= alive_wprocess_get.connect(infobase_wrapper)
          end

          def alive_wprocess_get
            wp_info = wprocesses.select{|p| p.Running == 1 && p.ping?}[0]
            fail 'No alive working processes found' unless wp_info
            wp_info
          end

          # Delete infobase
          # @param infobase_wrapper [InfoBaseWrapper] infobase wrapper
          # @param mode [Symbol] defines what should do with
          #   infobase's database. See {WpConnection::DROP_MODES}
          def drop_infobase!(infobase_wrapper, mode)
            wp_connection(infobase_wrapper).drop_infobase!(mode)
          end
        end
      end
    end
  end
end

