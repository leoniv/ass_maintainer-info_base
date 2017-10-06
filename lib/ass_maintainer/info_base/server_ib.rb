module AssMaintainer
  class InfoBase
    # Mixins for infobase deployed on 1C:Eneterprise server
    module ServerIb
      require 'ass_maintainer/info_base/server_ib/enterprise_servers'

      # @api private
      # Defauld destroyer for serever infobase
      class ServerBaseDestroyer

        # On default database will be destroyed!
        DROP_MODE = :destroy_db

        include Interfaces::IbDestroyer
        def entry_point
          infobase.infobase_wrapper.drop_infobase!(DROP_MODE)
        end
      end

      # @api private
      # Serever infobase maker
      class ServerBaseMaker < InfoBase::DefaultMaker
        REQUIRE_FIELDS = [:dbsrvr, :dbuid, :dbms]

        def entry_point
          prepare_making
          super
        end

        def prepare_making
          fail "Fields #{REQUIRE_FIELDS} must be filled" unless require_filled?
          infobase.prepare_making
        end

        def require_filled?
          REQUIRE_FIELDS.each do |f|
            return false if infobase.connection_string.send(f).nil?
          end
          true
        end
      end

      def maker
        options[:maker] || ServerBaseMaker.new
      end
      private :maker

      def destroyer
        options[:destroyer] || ServerBaseDestroyer.new
      end
      private :destroyer

      # @api private
      # Array of defined in +#connection_string.srvr+
      # 1C:Eneterprise clusters
      # @return [Array<EnterpriseServers::Cluster>]
      def clusters
        fail NotImplementedError,
            'Multiple servers deployments not supported' if\
            connection_string.servers.size > 1

        @clusters ||= connection_string.servers.map do |s|
          EnterpriseServers::Cluster
            .new("#{s.host}:#{s.port}", cluster_usr, cluster_pwd)
        end.uniq {|cl| [cl.host.upcase, cl.port.upcase]}
      end

      # @api private
      # Prepare connection string for making server infobase
      def prepare_making
        cs = connection_string
        set_if_empty :db, cs.ref
        set_if_empty :crsqldb, 'Y'
        set_if_empty :susr, cluster_usr
        set_if_empty :spwd, cluster_pwd
      end

      def set_if_empty(prop, value)
        connection_string.send("#{prop}=", value) if\
          connection_string.send(prop).to_s.empty?
      end
      private :set_if_empty

      # @api private
      # @return {InfoBaseWrapper}
      def infobase_wrapper
        @infobase_wrapper ||= InfoBaseWrapper.new(self)
      end

      def set_db_fields(dbsrvr, dbuid, dbpwd, dbms)
        connection_string.dbsrvr = dbsrvr
        connection_string.dbuid = dbuid
        connection_string.dbpwd = dbpwd
        connection_string.dbms = dbms
        nil
      end
      private :set_db_fields

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

        def wp_connection
          fail 'Infobase not exists' unless exists?
          clusters[0].wp_connection(self)
        end

        # Helper
        def ib_ref
          ib.connection_string.ref
        end

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

        # FIXME: True if infobase locked
        def locked?
          fail 'FIXME'
          wp_connection.locked? ib_ref
        end

        # FIXME: True if infobase locked and #unlock_code equal
        def locked_we?
          fail 'FIXME'
        end

        # Lock infoabse
        # @param from [Date Time] locking from time
        # @param to [Date Time] locking until time
        def lock(from: Time.now, to: Time.now + 3600, message: '')
          fail '#unlock_code is required' if ib.unlock_code.to_s.empty?
          raise 'FIXME'
          fail NotImplementedError
        end

        # Dlete infobase.
        # @note For first item calls {Cluster#drop_infobase!} with real
        #   +mode+ and uses mode == :alive_db for all other.
        #   Otherwise when mode == :destroy_db raises error
        #   "Не найдена база данных * в SQL-сервере *"
        # @param mode (see Cluster#drop_infobase!)
        def drop_infobase!(mode)
          clusters.each_with_index do |cl, index|
            cl.drop_infobase!(self, (index == 0 ? mode : :alive_db))
          end
        end
      end
    end
  end
end
