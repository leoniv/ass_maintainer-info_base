module AssMaintainer
  class InfoBase
    # Define absract Interfaces
    # for worker classes
    module Interfaces
      # Interface for class which make new InfoBase
      # Class must implement +#entry_point+ methodmodule Fixtures
      module IbMaker
        attr_reader :infobase
        def execute(infobase)
          @infobase = infobase
          entry_point
        end

        def entry_point
          fail NotImplementedError
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

        def entry_point
          fail NotImplementedError
        end
      end

      # Interface for {FileIb::InfoBaseWrapper} and
      # {ServerIb::InfoBaseWrapper} classes
      module InfoBaseWrapper
        require 'date'

        # Returns array of infobase sessions
        # For file infobase returns empty array
        # @return [Array <Session>]
        def sessions
          fail NotImplementedError
        end

        # Lock infobase. It work for server infobase only.
        # For file infobase it do nothing
        def lock(*_)
          fail NotImplementedError
        end

        # Unlock infobase which {#locked_we?}.
        # It work for server infobase only.
        # For file infobase it do nothing
        def unlock
          fail NotImplementedError
        end

        # Force unlock infobase.
        # It work for server infobase only.
        # For file infobase it do nothing
        def unlock!
          fail NotImplementedError
        end

        # Lock infobase. It work for server infobase only.
        # For file infobase it return +false+
        def locked?
          fail NotImplementedError
        end

        # True if infobase locked this
        # For file infobase it return +false+
        def locked_we?
          fail NotImplementedError
        end

        # True if infobase exists
        def exists?
          fail NotImplementedError
        end
      end
    end

    # Define abstract classes
    module Abstract
      class InfoBaseWrapper
        include Interfaces::InfoBaseWrapper
        attr_accessor :infobase
        alias_method :ib, :infobase
        def initialize(infobase)
          self.infobase = infobase
        end
      end
    end
  end
end
