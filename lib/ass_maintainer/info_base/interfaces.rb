module AssMaintainer
  class InfoBase
    # Riseses when infobase already locked and +InfoBase#unlock_code+
    # does not macth +PermissionCode+ on serever
    class UnlockError < StandardError; end

    # Raises when +InfoBase#unlock_code+ not setted
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

        # @note For {InfoBase::FileIb} must returns empty array
        # Returns array of infobase sessions
        # @return [Array <InfoBase::Session>]
        def sessions
          fail NotImplementedError
        end

        # @note It must work for {InfoBase::ServerIb} only.
        #  For {InfoBase::FileIb} it must do nothing
        # Locking infobase if it possible. Be careful it terminate all
        # sessions! Before do it should set +InfoBase#unlock_code+!
        # Schedule jobs will be locked to!
        # @raise [LockError] unless +InfoBase#unlock_code+ setted
        # @raise [UnlockError] unless soft {#unlock} possible. If catched
        #   it, shold do force unlock {unlock!} and try againe
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

        # @note For {InfoBase::FileIb} it must always return +false+
        #  It work for {InfoBase::ServerIb} only.
        # Return +true+ if on server flag +SessionsDenied == true+
        # and +PermissionCode+ setted
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
