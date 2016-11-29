module AssMaintainer
  class InfoBase
    module FileIb
      class FileBaseDestroyer
        include Interfaces::IbDestroyer
        def entry_point
          FileUtils.rm_r infobase.connection_string.path.to_s
        end
      end

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

      def make_connection_string
        connection_string
      end
    end
  end
end
