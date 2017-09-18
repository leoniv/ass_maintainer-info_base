module AssMaintainer
  class InfoBase
    # Mixins for infobase deployed on 1C:Eneterprise server
    module ServerIb
      require 'ass_maintainer/info_base/server_ib/helpers'
      # Defauld destroyer for serever infobase
      class ServerBaseDestroyer
        # Destroy modes
        MODES = {
          alive_db: 0,
          clear_db: 1,
          destroy_db: 2 }

        # On default database will be destroyed!
        DEF_MODE = :destroy_db

        include Interfaces::IbDestroyer
        def entry_point
          fail NotImplementedError
        end
      end

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

      # True if infobase exists
      def exists?
        infobase_wrapper.exists?
      end

      def destroyer
        options[:destroyer] || ServerBaseDestroyer.new
      end
      private :destroyer

      # @api private
      # Array of defined in +#connection_string.srvr+
      # 1C:Eneterprise clusters
      # @return [Array<EnterpriseServers::Cluster>]
      def clusters
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
        @infobase_wrapper = InfoBaseWrapper.new(self)
      end

      def set_db_fields(dbsrvr, dbuid, dbpwd, dbms)
        connection_string.dbsrvr = dbsrvr
        connection_string.dbuid = dbuid
        connection_string.dbpwd = dbpwd
        connection_string.dbms = dbms
        nil
      end
      private :set_db_fields
    end
  end
end
