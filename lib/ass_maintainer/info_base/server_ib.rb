module AssMaintainer
  class InfoBase
    class Session

      # see {#initialize} +app_id+
      attr_reader :app_id

      # see {#initialize} +host+
      attr_reader :host

      # see {#initialize} +id+
      attr_reader :id

      # see {#initialize} +user+
      attr_reader :user

      # see {#initialize} +infobase+
      attr_reader :infobase

      # @api private
      # @param id [Fixnum] sessions id
      # @param app_id [String] client application id
      # @param host [String] client host name
      # @param user [Strin] infobase user
      # @param infobase [InfoBase] infobase instance
      def initialize(id, app_id, host, user, infobase)
        @id = id
        @app_id = app_id
        @host = host
        @user = user
      end

      # Terminate session
      def terminate
        infobase.send(:infobase_wrapper).terminate(self) unless terminated?
      end

      # True if session is terminated
      def terminated?
        infobase.send(:infobase_wrapper).session_get(id).empty?
      end
    end

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
          infobase.send(:infobase_wrapper).drop_infobase!(DROP_MODE)
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
          cs = connection_string
          set_if_empty :db, cs.ref
          set_if_empty :crsqldb, 'Y'
          set_if_empty :susr, infobase.cluster_usr
          set_if_empty :spwd, infobase.cluster_pwd
        end

        def require_filled?
          REQUIRE_FIELDS.each do |f|
            return false if infobase.connection_string.send(f).nil?
          end
          true
        end

        def set_if_empty(prop, value)
          connection_string.send("#{prop}=", value) if\
            connection_string.send(prop).to_s.empty?
        end

        def connection_string
          infobase.connection_string
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

      # @return {InfoBaseWrapper}
      def infobase_wrapper
        @infobase_wrapper ||= InfoBaseWrapper.new(self)
      end
      private :infobase_wrapper

      # (see Interfaces::InfoBase#sessions)
      def sessions
        infobase_wrapper.sessions.map do |s|
          s.to_session(self)
        end
      end

      # (see Interfaces::InfoBase#lock)
      def lock(from: Time.now, to: Time.now + 3600, message: '')
        raise 'FIXME'
#FIXME  fail '#unlock_code is required' if ib.unlock_code.to_s.empty?
        nil
      end

      # (see Interfaces::InfoBase#unlock)
      def unlock
        raise 'FIXME'
        unlock!
        nil
      end

      # (see Interfaces::InfoBase#unlock!)
      def unlock!
        infobase_wrapper.wp_connection.unlock_schjobs!
        infobase_wrapper.wp_connection.unlock_sessions!
        nil
      end

      # (see Interfaces::InfoBase#lock_scjobs)
      def lock_scjobs
        infobase_wrapper.wp_connection.lock_schjobs!
        nil
      end

      # (see Interfaces::InfoBase#unlock_scjobs)
      def unlock_scjobs
        infobase_wrapper.wp_connection.unlock_schjobs!
        nil
      end

      # (see Interfaces::InfoBase#locked?)
      def locked?
        infobase_wrapper.wp_connection.locked?
      end

      # (see Interfaces::InfoBase#exists?)
      def exists?
        infobase_wrapper.clusters.size > 0
      end

      # @api private
      # Wrapper for manipulate
      # with real information base deployed in 1C:Enterprise server
      # ower the 1C Ole classes
      class InfoBaseWrapper
        attr_accessor :infobase
        alias_method :ib, :infobase
        def initialize(infobase)
          self.infobase = infobase
        end

        # @return [EnterpriseServers::ServerAgent]
        def sagent_get
          EnterpriseServers::ServerAgent
            .new "#{ib.sagent_host || cs_servers[0].host}:#{ib.sagent_port}",
                 ib.sagent_usr,
                 ib.sagent_pwd
        end
        private :sagent_get

        # @return [AssLauncher::Enterprise::Ole::AgentConnection]
        def sagent
          @sagent ||= sagent_get.connect(infobase.platform_require)
        end

        def cs_servers
          ib.connection_string.servers.uniq {|s| [s.host.upcase, s.port.upcase]}
        end
        private :cs_servers

        def cs_clusters
          cs_servers.map do |s|
            EnterpriseServers::Cluster
              .new("#{s.host}:#{s.port}", ib.cluster_usr, ib.cluster_pwd)
          end
        end
        private :cs_clusters

        def fail_multiple_servers_not_support
          fail NotImplementedError,
              'Multiple servers deployments not supported' if\
              cs_servers.size > 1
        end
        private :fail_multiple_servers_not_support

        # @return [Array<EnterpriseServers::Cluster>] clusters defined in
        # +#infobase.clusters+ attached into {#sagent}
        # @raise [RuntimeError] unsupport multiple servers infobase deployments
        def clusters
          fail_multiple_servers_not_support
          cs_clusters.select do |cl|
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

        # @param session [InfoBase::Session]
        def terminate(session)
          session_get(session.id).each do |s|
            s.terminate
          end
        end

        # Helper select session per +ID+. In normal returns arry with single
        # element or empty array
        # @return [Array<EnterpriseServers::Wrappers::Session>]
        def session_get(id)
          sessions.select {|s| s.SessionId().to_s == id.to_s}
        end

        # @return [Array<EnterpriseServers::Wrappers::Session>] infobase
        # sessions
        def sessions
          return [] unless exists?
          clusters.map do |cl|
            cl.infobase_sessions(ib_ref)
          end.flatten
        end

        # Dlete infobase.
        # @note For first item calls {EnterpriseServers::Cluster#drop_infobase!}
        #   with real +mode+ and uses mode == :alive_db for all other.
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
