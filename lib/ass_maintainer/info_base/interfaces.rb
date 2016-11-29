module AssMaintainer
  class InfoBase
    # Define absract Interfaces
    # for worker classes
    module Interfaces
        # Interface for class which fill data in InfoBase
        # Class must implement +#entry_point+ methodmodule Fixtures
        attr_reader :infobase
        def execute(infobase)
          @infobase = infobase
          entry_point
        end

        # Interface for class which make new InfoBase
        # Class must implement +#entry_point+ methodmodule Fixtures
        module IbMaker
          attr_reader :infobase
          def execute(infobase)
            @infobase = infobase
            entry_point
          end
        end

        # Interface for class which destroy InfoBase
        # Class must implement +#entry_point+ methodmodule Fixtures
        module IbDestroyer
          attr_reader :infobase
          def execute(infobase)
            @infobase = infobase
            entry_point
          end
        end
    end
  end
end
