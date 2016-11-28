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

      attr_accessor :agent, :claster, :db

      def maker
        options[:maker] || DefaultMaker.new
      end
      private :maker

      def exists?
        fail NotImplementsError
      end

      def distroer
        options[:distroer] || ServerBaseDestroyer.new
      end
      private :distroer
    end
  end
end
