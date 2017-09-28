require 'test_helper'
module AssMaintainer::InfoBaseTest
  module PrepareExample
    module RmInfobaseBefore
      extend Minitest::Spec::DSL
      attr_reader :example_ib
      before do
        @example_ib = AssMaintainer::InfoBase
          .new('test_infobase', Tmp::FILE_IB_CS, false)
        example_ib.rm! :yes if example_ib.exists?
      end

      after do
        example_ib.rm! :yes if example_ib.exists?
      end
    end

    module MakeInfobaseBefore
      extend Minitest::Spec::DSL
      attr_reader :example_ib
      before do
        @example_ib = AssMaintainer::InfoBase
          .new('test_infobase', Tmp::FILE_IB_CS, false)
        example_ib.make unless example_ib.exists?
      end

      after do
        example_ib.rm! :yes if example_ib.exists?
      end
    end

    module EsrvEnv
      require 'ass_launcher/cmd'
      require 'shellwords'
      class Parser < Clamp::Command
        include AssLauncher::Cmd::Abstract::Option::Dbms
        include AssLauncher::Cmd::Abstract::Option::Dbsrv
        include AssLauncher::Cmd::Abstract::Option::Esrv
        def execute; end
      end

      def esrv_env
        skip 'You must passes server environment via'\
          " environment variable `ESRV_ENV' for example:\n"
          '$ export ESRV_ENV="--ragent user:pass@host:port \\'\
          '  --rmngr user:pass@host:port \\'\
          '  --dbms MSSQLServer \\'\
          '  --dbsrv user:pass@localhost\\\\sqlexpress"' unless ENV['ESRV_ENV']
        ENV['ESRV_ENV']
      end

      def esrv_argv
        Shellwords.shellsplit(esrv_env)
      end

      def env_parser
        @env_parser ||= Parser.new('')
      end

      def bd_server

      end

      def enterprise_server

      end
    end
  end

  describe 'Make and remove infobase examples' do
    describe 'Make file infobase' do
      include PrepareExample::RmInfobaseBefore

      it 'example' do
        read_only = false
        # Get instance
        ib = AssMaintainer::InfoBase
          .new('test_infobase', Tmp::FILE_IB_CS, read_only)

        # Check infobase not exists
        ib.exists?.must_equal false
        File.file?(File.join(ib.connection_string.path, '1Cv8.1CD'))
          .must_equal false

        # Make infobase
        ib.make

        # Check infobase exists
        ib.exists?.must_equal true
        File.file?(File.join(ib.connection_string.path, '1Cv8.1CD'))
          .must_equal true
      end
    end

    describe 'Remove file infobase' do
      include PrepareExample::MakeInfobaseBefore

      it 'example' do
        read_only = false
        # Get instance
        ib = AssMaintainer::InfoBase
          .new('test_infobase', Tmp::FILE_IB_CS, read_only)

        # Check infobase exists
        ib.exists?.must_equal true
        File.file?(File.join(ib.connection_string.path, '1Cv8.1CD'))
          .must_equal true

        # Make infobase
        ib.rm! :yes

        # Check infobase not exists
        ib.exists?.must_equal false
        File.file?(File.join(ib.connection_string.path, '1Cv8.1CD'))
          .must_equal false
      end
    end

    describe 'WINDOWS_ONLY!' do
      include PrepareExample::EsrvEnv

      def skip_if_linux
        skip 'WINDOWS_ONLY!' if LINUX
      end

      before do
        skip_if_linux
        before_do if respond_to? :before_do
      end

      describe 'Make server infobase' do
        it 'example' do
          raise 'FIXME'
          skip 'NotImplemented'
        end
      end

      describe 'Remove server infobase' do
        it 'example' do
          raise 'FIXME'
          skip 'NotImplemented'
        end
      end
    end
  end

  describe 'Dumps examples' do
    include PrepareExample::MakeInfobaseBefore

    it 'Dump infobase to *.dt file' do
      # Get instance
      ib = AssMaintainer::InfoBase.new('name', Tmp::FILE_IB_CS)

      dump_path = File.join(Dir.tmpdir, "#{Tmp::IB_NAME}.dt")
      FileUtils.rm_rf dump_path

      # Dump infobase
      ib.dump dump_path

      # Checks for dump exists
      File.file?(dump_path).must_equal true
      # Clear all
      FileUtils.rm_rf dump_path
    end

    it 'Dump infobase configuration to *.cf file' do
      # Get instance
      ib = AssMaintainer::InfoBase.new('name', Tmp::FILE_IB_CS)

      dump_path = File.join(Dir.tmpdir, "#{Tmp::IB_NAME}.cf")
      FileUtils.rm_rf dump_path

      # Dump infobase configuration
      ib.cfg.dump dump_path

      # Checks for dump exists
      File.file?(dump_path).must_equal true
      # Clear all
      FileUtils.rm_rf dump_path
    end

    it 'Dump infobase configuration to XML files' do
      # Get instance
      ib = AssMaintainer::InfoBase.new('name', Tmp::FILE_IB_CS)

      dump_path = File.join(Dir.tmpdir, "#{Tmp::IB_NAME}.xmls")
      config_xml = File.join(dump_path, 'Configuration.xml')
      FileUtils.rm_rf dump_path
      FileUtils.mkdir dump_path

      # Dump infobase configuration to XML
      ib.cfg.dump_xml dump_path

      # Checks for dump exists
      File.directory?(dump_path).must_equal true
      File.file?(config_xml).must_equal true

      # Clear all
      FileUtils.rm_rf dump_path
    end

    it 'Dump database configuration to *.cf file' do
      # Get instance
      ib = AssMaintainer::InfoBase.new('name', Tmp::FILE_IB_CS)

      dump_path = File.join(Dir.tmpdir, "#{Tmp::IB_NAME}.cf")
      FileUtils.rm_rf dump_path

      # Dump infobase configuration
      ib.db_cfg.dump dump_path

      # Checks for dump exists
      File.file?(dump_path).must_equal true
      # Clear all
      FileUtils.rm_rf dump_path
    end
  end

  describe 'Load restore! and update examples' do
    include PrepareExample::RmInfobaseBefore

    def new_infobase
      ib = AssMaintainer::InfoBase
        .new('test_infobase', Tmp::FILE_IB_CS, false)
    end

    it 'Make new ifibase from infobase dump (aka *.dt file)' do
      ib = new_infobase
      ib.make
      ib.restore! Fixtures::DT_FILE
    end

    it 'Make new ifibase from configuration dump (aka *.cf file)' do
      ib = new_infobase
      ib.make
      ib.cfg.load Fixtures::CF_FILE
      ib.db_cfg.update
    end

    it 'Make new ifibase from configuration xml files' do
      ib = new_infobase
      ib.make
      ib.cfg.load_xml Fixtures::XML_FILES
      ib.db_cfg.update
    end
  end

  describe 'Other use cases' do
    def temporary_infobase
      AssMaintainer::InfoBase
        .new('test_infobase', Tmp::FILE_IB_CS, false)
    end

    def exists_infobse
      AssMaintainer::InfoBase
        .new('test_infobase', Tmp::FILE_IB_CS, false).make
    end

    it 'Dissemble .cf file to XML' do
      # Prepare
      dump_path = File.join(Dir.tmpdir, "#{Tmp::IB_NAME}.xmls")
      FileUtils.rm_rf dump_path
      FileUtils.mkdir dump_path

      ib = temporary_infobase
      ib.make
      ib.cfg.load Fixtures::CF_FILE
      ib.cfg.dump_xml dump_path

      # Clear all
      FileUtils.rm_rf dump_path
    end

    it 'Assemble .cf file from XML' do
      # Prepare
      dump_path = File.join(Dir.tmpdir, "#{Tmp::IB_NAME}.cf")
      FileUtils.rm_rf dump_path

      ib = temporary_infobase
      ib.make
      ib.cfg.load_xml Fixtures::XML_FILES
      ib.cfg.dump dump_path

      # Clear all
      FileUtils.rm_rf dump_path
    end

    it 'Dump database configuration to XML files' do
      # Preapare
      tmp_cf_file = File.join(Dir.tmpdir, "#{Tmp::IB_NAME}.cf")
      dump_path = File.join(Dir.tmpdir, "#{Tmp::IB_NAME}.xmls")
      FileUtils.rm_rf tmp_cf_file
      FileUtils.rm_rf dump_path
      FileUtils.mkdir dump_path

      source_ib = exists_infobse
      tmp_ib = temporary_infobase

      tmp_ib.make.cfg.load(
        source_ib.db_cfg.dump(tmp_cf_file)
      )

      tmp_ib.cfg.dump_xml dump_path

      # Clear
      FileUtils.rm_rf tmp_cf_file
      FileUtils.rm_rf dump_path
    end
  end

  describe 'InfoBase helpers example' do
    include PrepareExample::MakeInfobaseBefore

    def exists_infobse
      AssMaintainer::InfoBase
        .new('test_infobase', Tmp::FILE_IB_CS)
    end

    it 'Run designer for do something with infobase' do
      #For more info about commands see gem ass_launcher
      ib = exists_infobse
      cmd = ib.designer do
        checkConfig do
          webClient
          thinClient
          server
          externalConnection
        end
      end
      cmd.run.wait.result.verify!
    end

    it 'Run enterprise for do something in infobase' do
      #For more info about commands see gem ass_launcher
      ib = exists_infobse
      raise 'FIXME Fucking 1C'
      cmd = ib.enterprise :thick do
        _C 'Hello World'
        eXecute Fixtures::HELLO_EPF
      end

      cmd.run.wait.result.verify!
      cmd.process_holder.result.assout.must_equal "Hello World\r\n"
    end

    it 'Get Ole connector' do
      #For more info about Ole connectors see gem ass_launcher
      skip if LINUX
      ib = exists_infobse
      ib_connector = ib.ole :external
      ib_connector.__open__ ib.connection_string
      ib_connector.Metadata.Version.must_equal ''
      ib_connector.__close__
    end

    it 'Class InfoBase extend AssLauncher::Api' do
      AssMaintainer::InfoBase.singleton_class.include?(
        AssLauncher::Api).must_equal true
    end
  end
end
