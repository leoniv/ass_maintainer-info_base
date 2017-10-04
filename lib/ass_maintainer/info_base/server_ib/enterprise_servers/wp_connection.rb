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

          # @param infobase_wrapper [InfoBaseWrapper]
          def connect(infobase_wrapper)
            @infobase_wrapper = infobase_wrapper
            _connect host_port, sagent.platform_require
          end

          def infobase_name
            infobase_wrapper.ib_ref
          end

          def authenticate
            AuthenticateAdmin(cluster.user.to_s, cluster.password.to_s)
            authenticate_infobase_admin
          end

          def authenticate?
            return false unless connected?
            begin
              ole_connector.GetInfoBaseConnections(infobase_name)
            rescue
              return false
            end
            true
          end

          def infobase_exists?
            infobase_include? infobase_name
          end

          def drop_connections
            connections.each do |conn|
              Disconnect(conn)
            end
          end

          def authenticate_infobase_admin
            AddAuthentication(user, pass)
            fail "Authentication fault!" if !authenticate?
          end

          def drop_infobase(mode)
            fail ArgumentError, "Invalid mode #{mode}" unless DROP_MODES[mode]
            fail 'FIXME'
            #FIXME authenticate_infobase_admin(user, pass)
            #FIXME lock_sessions!(nil, nil, '')
            #FIXME lock_schjobs!
            drop_connections
            DropInfoBase(infobase_info, DROP_MODES[mode])
          end

          def infobase_info
            fail 'Infobase not exists' unless infobase_exists?
            infobase_find infobase_name
          end

          def locked?
            ii = infobase_info
            raise 'FIXME'
            ii.SessionsDenied && ii.PermissionCode != permission_code
          end

          def connections
            GetInfoBaseConnections(infobase_info)
          end

          def unlock_code
            infobase_wrapper.ib.unlock_code
          end

          def lock_sessions!(from, to, mess)
            fail ArgumentError, 'Permission code won\'t be empty' if\
              unlock_code.empty?
            ii = infobase_info
            ii.DeniedFrom = (from.nil? ? Date.parse('1973.09.07') : from).to_time
            ii.DeniedTo   = (to.nil? ? Date.parse('2073.09.07') : to).to_time
            ii.DeniedMessage = mess.to_s
            ii.SessionsDenied = true
            ii.PermissionCode = unlock_code
            UpdateInfoBase(ii)
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

          # @return [true false] old state of +ScheduledJobsDenied+
          def lock_schjobs!
            ii = infobase_info
            old_state = ii.ScheduledJobsDenied
            ii.ScheduledJobsDenied = true
            UpdateInfoBase(ii)
            old_state
          end

          # @param old_state [true false] state returned {#lock_schjobs!}
          def unlock_schjobs!
            ii = infobase_info
            ii.ScheduledJobsDenied = true
            UpdateInfoBase(ii)
          end

          def infobases
            GetInfoBases()
          end
        end
      end
    end
  end
end
