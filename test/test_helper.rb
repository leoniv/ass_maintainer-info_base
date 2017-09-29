$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'simplecov'
require 'ass_maintainer/info_base'
require 'minitest/autorun'
require 'mocha/mini_test'
module AssMaintainer::InfoBaseTest
  require 'test_helper/platform_require'
  require 'test_helper/helper'

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

  module FileBaseMaker
    extend Minitest::Spec::DSL

    attr_reader :ib
    before do
      @ib = AssMaintainer::InfoBase.new('name', Tmp::FILE_IB_CS)
    end
  end

  module ServerBaseMaker
    extend Minitest::Spec::DSL

    attr_reader :ib
    before do
      @ib = AssMaintainer::InfoBase.new('name', Tmp::SRV_IB_CS)
    end
  end

  module Fixtures
    PATH = File.expand_path('../fixtures', __FILE__)

    XML_FILES = File.join PATH, 'xml_files'
    fail unless File.directory? XML_FILES

    CF_FILE = File.join PATH, 'ib.cf'
    fail unless File.file? CF_FILE

    DT_FILE = File.join PATH, 'ib.dt'
    fail unless File.file? DT_FILE

    HELLO_EPF = File.join PATH, 'hello.epf'
    fail unless File.file? HELLO_EPF
  end

  require 'test_helper/esrv_env'
end
