module AssMaintainer
  class InfoBase
    # Mixins for file deployed infobase
    module FileIb
      # Default destroyer for file infobase
      class FileBaseDestroyer
        include Interfaces::IbDestroyer
        def entry_point
          FileUtils.rm_r infobase.connection_string.path.to_s
        end
      end

      # True if infobase exists
      def exists?
        File.file?("#{connection_string.path}/1Cv8.1CD")
      end

      def maker
        options[:maker] || InfoBase::DefaultMaker.new
      end
      private :maker

      def destroyer
        options[:destroyer] || FileBaseDestroyer.new
      end
      private :destroyer

      # Connection string fore createinfobase
      def make_connection_string
        connection_string
      end

      # Dummy infobase wrupper
      # @return [InfoBaseWrapper]
      def infobase_wrapper
        @infobase_wrapper = InfoBaseWrapper.new(self)
      end

      # (see Interfaces::InfoBaseWrapper)
      class InfoBaseWrapper
        include Interfaces::InfoBaseWrapper
        attr_accessor :infobase
        def initialize(infobase)
          self.infobase = infobase
        end

        # (see Interfaces::InfoBaseWrapper#sessions)
        def sessions
          []
        end

        # (see Interfaces::InfoBaseWrapper#lock)
        def lock
        end

        # (see Interfaces::InfoBaseWrapper#unlock)
        def unlock
        end

        # (see Interfaces::InfoBaseWrapper#unlock!)
        def unlock!
        end

        # (see Interfaces::InfoBaseWrapper#locked?)
        def locked?
          false
        end

        # (see Interfaces::InfoBaseWrapper#locked_we?)
        def locked_we?
          false
        end
      end
    end
  end
end
