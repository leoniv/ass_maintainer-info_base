module AssMaintainer
  #
  class InfoBase
    ASS_PLATFORM_REQUIRE = ENV['ASS_PLATFORM_REQUIRE'] || '> 0'

    # Settings for {InfoBase}
    class Config
      # Set reqirement for version of 1C:Enterprise
      attr_writer :platform_require
      # Reqirement for version of 1C:Enterprise
      # @return [String]
      def platform_require
        @platform_require ||= ASS_PLATFORM_REQUIRE
      end
    end

    # Make settings
    def self.configure
      yield config
    end

    # Get settings
    # @return [Config]
    def self.config
      @config ||= Config.new
    end
  end
end
