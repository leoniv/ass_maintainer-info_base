module AssMaintainer
  class InfoBase
    ASS_PLATFORM_REQUIRE = ENV['ASS_PLATFORM_REQUIRE'] || '> 0'

    class Config
      attr_writer :platform_require
      def platform_require
        @platform_require ||= ASS_PLATFORM_REQUIRE
      end
    end

    def self.configure
      yield config
    end

    def self.config
      @config ||= Config.new
    end

  end
end
