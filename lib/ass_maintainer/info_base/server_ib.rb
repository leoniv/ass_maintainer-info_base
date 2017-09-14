module AssMaintainer
  class InfoBase
    # Mixins for infobase deployed on 1C:Eneterprise server
    module ServerIb
      require 'ass_maintainer/info_base/server_ib/helpers'
      # Defauld destroyer for serever infobase
      class ServerBaseDestroyer
        include Interfaces::IbDestroyer
        def entry_point
          fail NotImplementedError
        end
      end

      def maker
        options[:maker] || InfoBase::DefaultMaker.new
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

      def filled?(fields)
        fields.each do |f|
          return false if connection_stringsend(f).nil?
        end
        true
      end
      private :filled?

      # Array of define in +srvr+ field of {#connection_string}
      # 1C:Eneterprise clusters
      # @return [Array<EnterpriseServers::Cluster>]
      def clusters
        connection_string.servers.map do |s|
          EnterpriseServers::Cluster
            .new("#{s.host}:#{s.port}", cluster_usr, cluster_pwd)
        end
      end

      # Connection string fore createinfobase
      def make_connection_string
        fields = [:dbsrvr, :db, :dbms]
        fail "Required fields #{fields} must be filled" unless filled?(fields)
        AssLauncher::Support::ConnectionString.new(connection_string.to_s)
      end

      # @return {InfoBaseWrapper}
      def infobase_wrapper
        @infobase_wrapper = InfoBaseWrapper.new(self)
      end
    end
  end
end
