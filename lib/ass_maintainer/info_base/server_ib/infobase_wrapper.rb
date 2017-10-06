module AssMaintainer
  class InfoBase
    module ServerIb
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
