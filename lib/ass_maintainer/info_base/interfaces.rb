module AssMaintainer
  class InfoBase
    # Riseses when infobase already locked and {InfoBase#unlock_code}
    # does not macth +PermissionCode+ on serever
    class UnlockError < StandardError; end

    # Raises when raises {UnlockError} or {Interfaces::InfoBase#sessions}
    # returns not empty array
    class LockError < StandardError; end

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

      # Common interface for different infobase types
      # Interface must be implemented in {InfoBase::FileIb} and
      # {InfoBase::ServerIb} modules
      module InfoBase
        require 'date'

        # @note For file infobase must returns empty array
        # Returns array of infobase sessions
        # @return [Array <InfoBase::Session>]
        def sessions
          fail NotImplementedError
        end

        # @note It must work for server infobase only.
        #  For file infobase it must do nothing
        # Soft locking infobase if it possible. For force locking infobase,
        # before do force unlocking #{unlock!}
        # @raise [LockError] unless locking possible
        def lock(from: Time.now, to: Time.now + 3600, message: '')
          fail NotImplementedError
        end

        # @note (see #lock}
        # Soft unlocking infobase if it possible.
        # For force unlocking exec #{unlock!}
        # @raise [UnlockError] unless unlocking possible
        def unlock
          fail NotImplementedError
        end

        # @note (see #lock}
        # Force unlock infobase.
        def unlock!
          fail NotImplementedError
        end

        # @note (see #lock}
        # Lock schedule jobs
        def lock_scjobs
          fail NotImplementedError
        end

        # @note (see #lock}
        # Unlock schedule jobs
        def unlock_scjobs
          fail NotImplementedError
        end

        # @note For file infobase it must always return +false+
        # Lock infobase. It work for server infobase only.
        def locked?
          fail NotImplementedError
        end

        # True if infobase exists
        def exists?
          fail NotImplementedError
        end
      end
    end
  end
end
