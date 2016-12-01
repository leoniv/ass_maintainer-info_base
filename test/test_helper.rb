$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'simplecov'
require 'ass_maintainer/info_base'
require 'minitest/autorun'
require 'mocha/mini_test'
module AssMaintainer::InfoBaseTest
  module Helper
    extend AssLauncher::Api
    extend AssLauncher::Support::Platforms

    AssLauncher::Support::Platforms.private_instance_methods.each do |m|
      public_class_method m
    end
  end
  PLATFORM_REQUIRE = '~> 8.3.9.0'
  AssMaintainer::InfoBase.configure do |c|
    c.platform_require = PLATFORM_REQUIRE
  end

  module Clients
    THICK = Helper.thicks(PLATFORM_REQUIRE).last
    "Platform  #{PLATFORM_REQUIRE} not found" unless THICK
  end

  LINUX = Helper.linux?

  module Tmp
    TMP_DIR = Dir.tmpdir
    IB_NAME = 'ass_maintainer_infobase_test'
    FILE_IB_CS = Helper.cs_file file: File.join(TMP_DIR,"#{IB_NAME}.ib.tmp")
    SRV_IB_CS = Helper.cs_srv srvr: 'localhost', ref: IB_NAME
  end
end
