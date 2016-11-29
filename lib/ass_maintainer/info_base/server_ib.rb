module AssMaintainer
  class InfoBase
    module ServerIb
      require 'ass_maintainer/info_base/server_ib/helpers'
      class ServerBaseDestroyer
        include Interfaces::IbDestroyer
        def entry_point
          fail NotImplementsError
        end
      end

      def maker
        options[:maker] || InfoBase::DefaultMaker.new
      end
      private :maker

      def exists?
        fail NotImplementsError
      end

      def distroer
        options[:distroer] || ServerBaseDestroyer.new
      end
      private :distroer

      # @return [EnterpriseServer::ServerAgent nil]
      attr_reader :server_agent
      # @param [EnterpriseServer::ServerAgent]
      def server_agent=(a)
        fail ArgumentError unless a.instance_of? ServerAgent
        @server_agent = a
      end

      # Claster user name
      # @param user_name [String]
      def cluster_usr(user_name)
        connection_string.susr = user_name
      end

      # Claster user password
      # @param password [String]
      def cluster_pwd(password)
        connection_string.spwd = password
      end

      # @return [EnrepriseServers::Claster]
      def claster
        Claster.from_cs(connection_string)
      end

      def filled?(fields)
        files.each do |f|
          return false if connection_string[f].nil?
        end
        true
      end
      private :filled?

      def make_connection_string
        fields = [:dbsrvr, :db, :dbms]
        fail "Required fields #{fields} must be filled" unless filled?(fields)
        AssLauncher::Support::ConnectionString.new(connection_string.to_s)
      end
    end
  end
end
