module AssMaintainer
  class InfoBase
    module ServerIb
      require 'ass_maintainer/info_base/server_ib/helpers'
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

      def exists?
        infobase_wrapper.exists?
      end

      def distroer
        options[:distroer] || ServerBaseDestroyer.new
      end
      private :distroer

      # @return (see #def_server_agent)
      def server_agent
        @server_agent ||= def_server_agent
      end

      # @return [EnterpriseServers::ServerAgent]
      def def_server_agent
        host = sagent_host || connection_string.servers[0].host
        port = sagent_port || InfoBase::DEFAULT_SAGENT_PORT
        EnterpriseServers::ServerAgent.new("#{host}:#{port}",
                                         sagent_usr,
                                         sagent_pwd)
      end
      private :def_server_agent

      # @param [EnterpriseServers::ServerAgent]
      def server_agent=(a)
        fail ArgumentError unless a.instance_of? ServerAgent
        @server_agent = a
      end

      # Set claster user name
      # @param user_name [String]
      def cluster_usr=(user_name)
        connection_string.susr = user_name
      end

      # Claster user name
      def claster_usr
        connection_string.susr || (claster_usr = options[:claster_usr])
      end

      # Set claster user password
      # @param password [String]
      def cluster_pwd=(password)
        connection_string.spwd = password
      end

      # Claster user password
      def claster_pwd
        connection_string.spwd || (claster_pwd = options[:claster_pwd])
      end

      # @return [EnrepriseServers::Claster]
      def claster
        EnterpriseServers::Claster.from_cs(connection_string)
      end

      def filled?(fields)
        files.each do |f|
          return false if connection_string[f].nil?
        end
        true
      end
      private :filled?

      # Connection string fore createinfobase
      def make_connection_string
        fields = [:dbsrvr, :db, :dbms]
        fail "Required fields #{fields} must be filled" unless filled?(fields)
        AssLauncher::Support::ConnectionString.new(connection_string.to_s)
      end

      def infobase_wrapper
        @infobase_wrapper = InfoBaseWrapper.new(self, server_agent, claster)
      end
    end
  end
end
