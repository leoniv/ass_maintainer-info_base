module AssMaintainer
  class InfoBase
    module Abstract
      # @abstract
      class Cfg
        attr_reader :infobase
        # @param infobase [InfoBase]
        def initialize(infobase)
          @infobase = infobase
        end
      end
    end

    # Object for manipuate whith infobase configuration
    class Cfg < Abstract::Cfg
      # Dump configuration to +XML+ files
      # @param path [String]
      # @return [String] path
      def dump_xml(path)
        infobase.designer do
          dumpConfigToFiles path
        end.run.wait.result.verify!
        path
      end

      # Dump configuration to +.cf+ file
      # @param path [String]
      # @return [String] path
      def dump(path)
        infobase.designer do
          dumpCfg path
        end.run.wait.result.verify!
        path
      end

      # Load configuration from +XML+ files
      # @param path [String]
      # @return [String] path
      def load_xml(path)
        fail MethodDenied, :load_xml if infobase.read_only?
        infobase.designer do
          loadConfigFromFiles path
        end.run.wait.result.verify!
        path
      end

      # Load configuration from +.cf+ file
      # @param path [String]
      # @return [String] path
      def load(path)
        fail MethodDenied, :load_cf if infobase.read_only?
        infobase.designer do
          loadCfg path
        end.run.wait.result.verify!
        path
      end
    end

    # Object for manipuate whith database configuration
    class DbCfg < Abstract::Cfg
      # Update database configuration from infobase
      # configuration
      # @param was_err [true false] control +warningsAsErrors+ 1C:Enterprise
      #  CLI parameter
      def update(was_err = false)
        fail MethodDenied, :update if infobase.read_only?
        infobase.designer do
          updateDBCfg do
            warningsAsErrors if was_err
          end
        end.run.wait.result.verify!
      end

      # Dump configuration to +.cf+ file
      # @param path [String]
      # @return [String] path
      def dump(path)
        infobase.designer do
          dumpDBCfg path
        end.run.wait.result.verify!
        path
      end
    end
  end
end
