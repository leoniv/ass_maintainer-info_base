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

      def maker
        options[:maker] || InfoBase::DefaultMaker.new
      end
      private :maker

      def destroyer
        options[:destroyer] || FileBaseDestroyer.new
      end
      private :destroyer

      # (see Interfaces::InfoBase#sessions)
      def sessions
        []
      end

      # (see Interfaces::InfoBase#lock)
      def lock(*_)
      end

      # (see Interfaces::InfoBase#unlock)
      def unlock
      end

      # (see Interfaces::InfoBase#unlock!)
      def unlock!
      end

      # (see Interfaces::InfoBase#locked?)
      def locked?
        false
      end

      # (see Interfaces::InfoBase#locked_we?)
      def locked_we?
        false
      end

      # (see Interfaces::InfoBase#locked_we?)
      def exists?
        File.file?("#{connection_string.path}/1Cv8.1CD")
      end
    end
  end
end
