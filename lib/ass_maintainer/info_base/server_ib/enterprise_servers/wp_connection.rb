module AssMaintainer
  class InfoBase
    module ServerIb
      require 'ass_ole'
      module EnterpriseServers
        # @api private
        # Object for comunication with 1C Working process.
        # @example
        #   wp_connection = WpConnection.new(wp_info).connect(infobase_wrapper)
        module WpConnection
          # Drop infobase modes defines what should do with infobase's database.
          # - 0 - databse willn't be deleted
          # - 1 - databse will be deleted
          # - 2 - database willn't be deleted but will be cleared
          DROP_MODES = {alive_db: 0, destroy_db: 1, clear_db: 2}.freeze

          include Support::OleRuntime
          include Support::InfoBaseFind
          include Support::Reconnect

          # Make new object of anonymous class which included this module.
          # @param wp_info (see #initialize)
          def self.new(wp_info)
            Class.new do
              include WpConnection
            end.new wp_info
          end

          attr_reader :infobase_wrapper

          attr_reader :wp_info

          # @param wp_info [Wrappers::WorkingProcessInfo]
          def initialize(wp_info)
            @wp_info = wp_info
          end

          def runtime_type
            :wp
          end

          def sagent
            wp_info.sagent
          end

          def cluster
            wp_info.cluster
          end

          def host_port
            "#{wp_info.HostName}:#{wp_info.MainPort}"
          end

          def user
            infobase_wrapper.ib.usr.to_s
          end

          def pass
            infobase_wrapper.ib.pwd.to_s
          end

          def ping?
            wp_info.ping?
          end

          # @param infobase_wrapper [InfoBaseWrapper]
          def connect(infobase_wrapper)
            @infobase_wrapper = infobase_wrapper
            _connect host_port, sagent.platform_require
          end

          def ib_ref
            infobase_wrapper.ib_ref
          end

          def authenticate
            AuthenticateAdmin(cluster.user.to_s, cluster.password.to_s)
            authenticate_infobase_admin
          end

          def authenticate_infobase_admin
            AddAuthentication(user, pass)
            ole_connector.GetInfoBaseConnections(ib_info_create)
            true
          end

          def ib_info_create
            ii = createInfoBaseInfo
            ii.Name = ib_ref
            ii
          end

          def authenticate?
            false
          end

          def infobase_exists?
            infobase_include? ib_ref
          end

          def drop_infobase!(mode)
            fail ArgumentError, "Invalid mode #{mode}" unless DROP_MODES[mode]
            lock_infobase!(nil, nil, "BEFORE DROP INFOBASE", '')
            DropInfoBase(infobase_info, DROP_MODES[mode])
          end

          def infobase_info
            fail 'Infobase not exists' unless infobase_exists?
            authenticate_infobase_admin
            infobase_find ib_ref
          end

          def locked?
            ii = infobase_info
            ii.SessionsDenied
          end

          def connections
            GetInfoBaseConnections(infobase_info)
          end

          def lock_sessions!(from, to, code, mess)
            fail ArgumentError, 'Permission code won\'t be empty' if\
              code.to_s.empty?
            ii = infobase_info
            ii.DeniedFrom = (from.nil? ? Date.parse('1973.09.07') : from).to_time
            ii.DeniedTo   = (to.nil? ? Date.parse('2073.09.07') : to).to_time
            ii.DeniedMessage = mess.to_s
            ii.SessionsDenied = true
            ii.PermissionCode = code
            UpdateInfoBase(ii)
          end

          def drop_sessions
            infobase_wrapper.sessions.each do |sess|
              sess.terminate
            end
          end

          def drop_connections
            connections.each do |conn|
              Disconnect(conn)
            end
          end

          def lock_infobase!(from, to, code, mess)
            lock_sessions!(from, to, code, mess)
            lock_schjobs!
            drop_sessions
            drop_connections
          end

          def unlock_sessions!
            ii = infobase_info
            ii.DeniedFrom          = Date.parse('1973.09.07').to_time
            ii.DeniedTo            = Date.parse('1973.09.07').to_time
            ii.DeniedMessage       = ''
            ii.SessionsDenied      = false
            ii.PermissionCode      = ''
            UpdateInfoBase(ii)
          end

          def lock_schjobs!
            ii = infobase_info
            ii.ScheduledJobsDenied = true
            UpdateInfoBase(ii)
          end

          def unlock_schjobs!
            ii = infobase_info
            ii.ScheduledJobsDenied = false
            UpdateInfoBase(ii)
          end

          def infobases
            reconnect
            getInfoBases
          end

          def _reconnect_required?
            getInfoBases.empty?
          end
          private :reconnect_required?
        end
      end
    end
  end
end
