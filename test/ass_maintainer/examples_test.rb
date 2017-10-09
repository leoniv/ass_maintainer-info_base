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
  end

  module SkipIfLinux
    def skip_if_linux
      skip 'WINDOWS_ONLY!' if LINUX
    end
  end

  describe 'Restrictions for' do
    describe 'Server infobase' do
      it 'Not working in Linux' do
        skip unless LINUX

        cs = AssMaintainer::InfoBase.cs_srv srvr: "host1", ref: 'facke_ib'

        ib = AssMaintainer::InfoBase.new('insatnce_name', cs)

        e = proc {
          ib.exists?
        }.must_raise NotImplementedError

        e.message.must_match %{WIN32OLE undefined for this machine}
      end

      it 'Multiple clusters deployment not supported' do
        cs = AssMaintainer::InfoBase.cs_srv srvr: "host1,host2", ref: 'facke_ib'

        # Infobase is deployed on multiple clusters 'host1' and 'host2'
        cs.servers.size.must_equal 2

        ib = AssMaintainer::InfoBase.new('insatnce_name', cs)

        e = proc {
          ib.exists?
        }.must_raise NotImplementedError
        e.message.must_match %r{Multiple clusters deployment not supported}i
      end
    end

    describe 'All infobase' do
      include PrepareExample::RmInfobaseBefore

      it 'in #read_only? infobases dangerous methods fails' do
        ib = AssMaintainer::InfoBase.new('instance name', Tmp::FILE_IB_CS)

        ib.read_only?.must_equal true

        e = proc {
          ib.make
        }.must_raise AssMaintainer::InfoBase::MethodDenied

        e.message.must_match %r{Infobase is read only\. Method make.+ denied!}
      end
    end
  end

  describe 'Differences beetween Server and File types infobases' do
    describe 'File infobase' do
      it 'basic usage example' do
        # Prepare file infobase connection string (via AssLauncher::Api mixin)
        cs = AssMaintainer::InfoBase.cs_file(file: File.join(Dir.tmpdir, "fake_infobase_#{hash}.ib"))

        # Get instance
        ib = AssMaintainer::InfoBase.new('instace_name', cs)

        # And play whth instance
        ib.exists?.must_equal false

        # Fails because infobase not exists
        e = proc {
          ib.dump('fake_path')
        }.must_raise RuntimeError
        e.message.must_match %r{Infobase not exists}
      end

      it 'make and remove example' do
        # Prepare file infobase connection string (via AssLauncher::Api mixin)
        cs = AssMaintainer::InfoBase.cs_file(file: File.join(Dir.tmpdir, "fake_infobase_#{hash}.ib"))

        # Get instance with read_only == false
        ib = AssMaintainer::InfoBase.new('instace_name', cs, false)

        # And play with instance
        ib.exists?.must_equal false
        ib.make # make empty file infobase

        ib.exists?.must_equal true

        # Open session with infobase
        designer = ib.designer
        designer.run

        sleep 3 # wait while designer raising

        begin
          # Session alive and rm! should fall
          e = proc {
            ib.rm! :yes # remove infobase
          }.must_raise Errno::ENOTEMPTY

          # Kill session
          designer.process_holder.kill

          # Session killed and rm! shouldn't fall
          ib.rm! :yes # remove infobase
          ib.exists?.must_equal false
        ensure
          designer.process_holder.kill if designer
        end
      end
    end

    describe 'Server infobase' do
      include EsrvEnv
      include SkipIfLinux

      before do
        skip_if_linux
      end

      it 'basic usage example' do
        # Prepare file infobase connection string (via AssLauncher::Api mixin)
        cs = AssMaintainer::InfoBase.cs_srv(srvr: "#{env_parser.cluster_host}:#{env_parser.cluster_port}",
                           ref: "delete_me_fake_infobase_#{hash}")

        # Server infobase required connecting to
        # 1C:Enterprise services sach as "Server agent: ragent.exe" and
        # "Cluster: rmngr.exe" for detects exists infobase or not, lock/unlock
        # infobase, getting sessions etc.

        # Get new instance because for old instance will not work
        ib = AssMaintainer::InfoBase.new(
          'instance_name', cs,
          # Passing to instance 1C services connection parameters via options.
          # But If your ragent.exe and rmngr.exe running on one host and has
          # standart ports and doesn't have a admins this step not required.
          sagent_host: env_parser.sagent_host, # Optional dragent.exe host name. Default uses, #srvr host from connection string
          sagent_port: env_parser.sagent_port, # Optional ragent.exe port. Default is 1540.
          sagent_usr: env_parser.sagent_usr, # Optional ragent.exe admin name
          sagent_pwd: env_parser.sagent_pwd, # Optional ragent.exe admin password
          cluster_usr: env_parser.cluster_usr, # Optional rmngr.exe admin name
          cluster_pwd: env_parser.cluster_pwd # Optional rmngr.exe admin password
        )

        # And play whth instance
        ib.exists?.must_equal false

        # Fails because infobase not exists
        e = proc {
          ib.dump('fake_path')
        }.must_raise RuntimeError
        e.message.must_match %r{Infobase not exists}
      end

      it 'make and remove example' do
        # Prepare file infobase connection string (via AssLauncher::Api mixin)
        cs = AssMaintainer::InfoBase
          .cs_srv(srvr: "#{env_parser.cluster_host}:#{env_parser.cluster_port}",
                  ref: "delete_me_fake_infobase_#{hash}")

        # Get instance with read_only == false
        ib = AssMaintainer::InfoBase.new(
          'instance_name', cs, false,
          # Passing to instance 1C services connection parameters via options.
          sagent_host: env_parser.sagent_host,
          sagent_port: env_parser.sagent_port,
          sagent_usr: env_parser.sagent_usr,
          sagent_pwd: env_parser.sagent_pwd,
          cluster_usr: env_parser.cluster_usr,
          cluster_pwd: env_parser.cluster_pwd
        )

        # And play with instance
        ib.exists?.must_equal false

        # It fail because for make server infobase require passing DBMS
        # parameters
        e = proc {
          ib.make
        }.must_raise RuntimeError
        e.message.must_match %r{Fields \[:dbsrvr, :dbuid, :dbms\] must be filled}

        # Passinng DBMS parameters:
        ib.connection_string.dbms   = env_parser.dbms # required type of DBMS
        ib.connection_string.dbsrvr = env_parser.dbsrv_host # required DMBS host
        ib.connection_string.dbuid  = env_parser.dbsrv_usr # optional DMBS user name
        ib.connection_string.dbpwd  = env_parser.dbsrv_pwd # optional DBMS user password
        ib.connection_string.db     = cs.ref # optional. Default uses #ref value of connection string

        ib.make # make empty server ib
        ib.exists?.must_equal true

        # Open session with infobase
        thick = ib.ole(:thick)
        thick.__open__ ib.connection_string

        begin
          ib.sessions.map {|i| i.app_id}.must_include('1CV8')

          # All sessions will be dropped and infobase will be removed
          ib.rm! :yes # remove ib
          ib.exists?.must_equal false
        ensure
          thick.__close__ if thick
        end
      end
    end
  end

  describe 'Infobase type sensitive examples' do
    include SkipIfLinux

    describe 'Server infobase' do
      include EsrvEnv

      def cluster_host_port
        "#{env_parser.cluster_host}:#{env_parser.cluster_port}"
      end

      def example_ib
        # Prepare file infobase connection string (via AssLauncher::Api mixin)
        cs = AssMaintainer::InfoBase
          .cs_srv(srvr: "#{env_parser.cluster_host}:#{env_parser.cluster_port}",
                  ref: "delete_me_fake_infobase_#{hash}",
                  dbms: env_parser.dbms,
                  dbsrvr: env_parser.dbsrv_host,
                  dbuid: env_parser.dbsrv_usr,
                  dbpwd: env_parser.dbsrv_pwd,
                  susr: env_parser.cluster_usr,
                  spwd: env_parser.cluster_pwd)


        @example_ib ||= (
            ib = AssMaintainer::InfoBase.new(
            'instance_name', cs, false, sagent_host: env_parser.sagent_host,
            sagent_port: env_parser.sagent_port, sagent_usr: env_parser.sagent_usr,
            sagent_pwd: env_parser.sagent_pwd, cluster_usr: env_parser.cluster_usr,
            cluster_pwd: env_parser.cluster_pwd).make
            ib.restore! Fixtures::DT_FILE_WITH_ROOT_USER
            ib.usr = 'root'
            ib
        )
      end

      before do
        skip_if_linux
      end

      after do
        @example_ib.rm! :yes if @example_ib
      end

      def assert_real_locked(ib, from, to, mess)
        ii = ib.send(:infobase_wrapper).wp_connection.infobase_info
        ii.PermissionCode.must_equal ib.unlock_code
        ii.SessionsDenied.must_equal true
        ii.DeniedFrom.to_s.must_equal from.to_s
        ii.DeniedTo.to_s.must_equal to.to_s
        ii.DeniedMessage.must_equal mess
        ii.ScheduledJobsDenied.must_equal true
      end

      def assert_real_ulocked(ib)
        ii = ib.send(:infobase_wrapper).wp_connection.infobase_info
        ii.SessionsDenied.must_equal false
      end

      describe 'Lock unlock infobase' do
        it 'lock unlock example' do
          ib = example_ib
          ib.locked?.must_equal false
          assert_real_ulocked(ib)

          # Open session with infobase
          external = ib.ole(:external)
          external.__open__ ib.connection_string

          # Sessions include external connection
          ib.sessions.map {|s| s.app_id}.must_include 'COMConnection'

          # Unset #unlock_code
          ib.unlock_code = ''
          e = proc {
            ib.lock
          }.must_raise AssMaintainer::InfoBase::LockError
          e.message.must_match %r{unlock_code is required}

          ib.unlock_code = 'good unlock_code'
          from = Time.now - 10
          to = Time.now + 10
          mess = 'lock message'
          ib.lock(from: from, to: to, message: mess).must_be_nil

          # Ib is locked
          ib.locked?.must_equal true
          assert_real_locked(ib, from, to, mess)

          # And all sessions terminated
          ib.sessions.size.must_equal 0, ib.sessions.map {|s| s.app_id}.to_s

          ib.unlock_code = 'bad unlock_code'
          e = proc {
            ib.unlock.must_be_nil
          }.must_raise AssMaintainer::InfoBase::UnlockError
          e.message.must_match %r{not match unlock_code: `bad unlock_code'}

          ib.unlock!.must_be_nil

          ib.locked?.must_equal false
        end

        it 'lock_schjobs unlock_schjobs example' do
          ib = example_ib

          ib.send(:infobase_wrapper).wp_connection.infobase_info.ScheduledJobsDenied
            .must_equal false

          ib.lock_schjobs

          ib.send(:infobase_wrapper).wp_connection.infobase_info.ScheduledJobsDenied
            .must_equal true

          ib.unlock_schjobs

          ib.send(:infobase_wrapper).wp_connection.infobase_info.ScheduledJobsDenied
            .must_equal false
        end
      end

      describe 'Infobase sessions' do
        it 'example' do
          ib = example_ib
          ib.exists?.must_equal true

          # Open session with infobase
          external = ib.ole(:external)
          external.__open__ ib.connection_string

          ib.sessions.map {|s| "#{s.app_id}:#{s.user}"}.must_include 'COMConnection:root'

          # Terminate all sessions
          ib.sessions.each do |sess|
            sess.terminated?.must_equal false
            sess.terminate
            sess.terminated?.must_equal true
          end

          ib.sessions.size.must_equal 0
        end
      end
    end

    describe 'File infobase' do
      describe 'Lock unlock infobase' do
        include PrepareExample::MakeInfobaseBefore

        it '#lock, #unlock, #unlock! do nothing and #locked? always false' do
          # Get instance
          ib = example_ib

          ib.locked?.must_equal false

          ib.lock.must_be_nil

          ib.locked?.must_equal false

          ib.unlock.must_be_nil
          ib.unlock!.must_be_nil

          ib.locked?.must_equal false
        end
      end

      describe 'Infobase sessions' do
        include PrepareExample::MakeInfobaseBefore

        it '#sessions always returns empty array' do
          # Get instance
          ib = example_ib

          # #sessions returns empty array
          ib.sessions.must_be :empty?

          skip_if_linux

          # Get external connection object
          external = ib.ole(:external)

          begin
            # Connect to infobase
            external.__open__ ib.connection_string

            # External connection is opened
            external.__opened__?.must_equal true

            # But #sessions always returns empty array
            ib.sessions.must_be :empty?
          ensure
            external.__close__ if external
          end
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
    include SkipIfLinux

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
      cmd = ib.enterprise :thick do
        _C 'Hello World'
      end

      # Run Eneterprise
      cmd.run
      sleep(3) #Wait while Enterprise up

      begin
        cmd.process_holder.running? .must_equal true
      ensure
        # Kill Enterprise
        cmd.process_holder.kill
      end
    end

    it 'Get Ole connector' do
      #For more info about Ole connectors see gem ass_launcher
      skip_if_linux
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
