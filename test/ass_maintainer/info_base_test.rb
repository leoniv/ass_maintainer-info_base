require 'test_helper'

module AssMaintainer::InfoBaseTest
  describe AssMaintainer::InfoBase::VERSION do
    it 'VERSION setted' do
      ::AssMaintainer::InfoBase::VERSION.wont_equal nil
    end
  end

  module CommonInfobaseTests
    extend Minitest::Spec::DSL

    it '#add_hook raises' do
      e = proc {
        ib.add_hook :bad_hook
      }.must_raise ArgumentError
      e.message.must_match %r{Invalid hook}

      e = proc {
        ib.add_hook :before_make
      }.must_raise ArgumentError
      e.message.must_match %r{Block require}
    end

    AssMaintainer::InfoBase::HOOKS.keys.each do |hook|
      it "#add_hook :#{hook}" do
        ib.add_hook hook do |ib_|
          ib_
        end
        ib.send(hook).call(ib).must_equal ib
      end
    end

    it '#platform_require' do
      ib.platform_require.must_equal ib.class.config.platform_require
      ib.platform_require = :new_require
      ib.platform_require.must_equal :new_require
    end

    it '#rebuild' do
      ib.expects(:rm!).with(:sure)
      ib.expects(:make).returns(:make)
      ib.rebuild!(:sure).must_equal :make
    end

    it '#make exists infobase' do
      ib.expects(:exists?).returns(true)
      ib.expects(:make_infobase!).never
      ib.make.must_equal ib
    end

    it '#make not exists infobase' do
      seq = sequence('sec')
      hook = mock
      hook.expects(:call).with(ib).twice
      maker = mock
      maker.expects(:execute).with(ib)
      ib.expects(:exists?).returns(false)
      ib.expects(:read_only?).in_sequence(seq).returns(false)
      ib.expects(:before_make).in_sequence(seq).returns(hook)
      ib.expects(:maker).in_sequence(seq).returns(maker)
      ib.expects(:after_make).in_sequence(seq).returns(hook)
      ib.make.must_equal ib
    end

    it '#rm! requires assurance' do
      e = proc {
        ib.rm!
      }.must_raise RuntimeError
      e.message.must_match %r{If you are sure pass :yes value}i
    end

    it '#rm! not exists infobase' do
     ib.expects(:exists?).returns(false)
     ib.expects(:rm_infobase!).never
     assert_nil ib.rm!(:yes)
    end

    it '#rm! exists infobase' do
      seq = sequence('sec')
      hook = mock
      hook.expects(:call).with(ib).twice
      destroyer = mock
      destroyer.expects(:execute).with(ib)
      ib.expects(:exists?).returns(true)
      ib.expects(:read_only?).in_sequence(seq).returns(false)
      ib.expects(:before_rm).in_sequence(seq).returns(hook)
      ib.expects(:destroyer).in_sequence(seq).returns(destroyer)
      ib.expects(:after_rm).in_sequence(seq).returns(hook)
      assert_nil ib.rm!(:yes)
    end

    it '#connection_string' do
      ib.connection_string.must_be_instance_of @cs_class
    end

    it '#is' do
      cs = mock('name')
      cs.expects(:is).returns(:is_value)
      ib.expects(:connection_string).returns(cs)
      ib.is.must_equal :is_value
    end

    it '#is smoky' do
      ib.is.must_be_instance_of Symbol
    end

    it '#is?' do
      cs = mock
      cs.expects(:is?).with(:is_value).returns(:is_true)
      ib.expects(:connection_string).returns(cs)
      ib.is?(:is_value).must_equal(:is_true)
    end

    it '#is? smoky' do
      ib.is?(:bad).must_equal false
    end

    it '#usr' do
      cs = mock
      cs.expects(:usr).returns(:usr_value)
      ib.expects(:connection_string).returns(cs)
      ib.usr.must_equal :usr_value
    end

    it '#usr=' do
      cs = mock
      cs.expects(:usr=).with(:usr_value).returns(:usr_value)
      ib.expects(:connection_string).returns(cs)
      (ib.usr = :usr_value).must_equal :usr_value
    end

    it '#usr and #usr= smoky' do
      ib.usr = :user_name
      ib.usr.must_equal :user_name
    end

    it '#pwd' do
      cs = mock
      cs.expects(:pwd).returns(:pwd_value)
      ib.expects(:connection_string).returns(cs)
      ib.pwd.must_equal :pwd_value
    end

    it '#pwd=' do
      cs = mock
      cs.expects(:pwd=).with(:pwd_value).returns(:pwd_value)
      ib.expects(:connection_string).returns(cs)
      (ib.pwd = :pwd_value).must_equal :pwd_value
    end

    it '#pwd and #pwd= smoky' do
      ib.pwd = :user_name
      ib.pwd.must_equal :user_name
    end

    it '#locale=' do
      cs = mock
      cs.expects(:locale=).with(:locale_value).returns(:locale_value)
      ib.expects(:connection_string).returns(cs)
      (ib.locale = :locale_value).must_equal :locale_value
    end

    it '#locale' do
      cs = mock
      cs.expects(:locale).returns(:locale_value)
      ib.expects(:connection_string).returns(cs)
      ib.locale.must_equal :locale_value
    end

    it '#locale and #locale= smoky' do
      ib.locale = :locale
      ib.locale.must_equal :locale
    end

    it '#thick' do
      ib.thick.must_be_instance_of\
        AssLauncher::Enterprise::BinaryWrapper::ThickClient
    end

    it '#thick fail' do
      ib.expects(:platform_require).returns('> 999').twice
      e = proc {
        ib.thick
      }.must_raise RuntimeError
      e.message.must_match %r{Platform 1C > 999 not found}
    end

    it '#thin' do
      ib.thin.must_be_instance_of\
        AssLauncher::Enterprise::BinaryWrapper::ThinClient
    end

    it '#thin fail' do
      ib.expects(:platform_require).returns('> 999').twice
      e = proc {
        ib.thin
      }.must_raise RuntimeError
      e.message.must_match %r{Platform 1C > 999 not found}
    end

    it '#ole' do
      skip if LINUX
      ib.ole(:external).must_be_instance_of\
        AssLauncher::Enterprise::Ole::IbConnection
      ib.ole(:wprocess).must_be_instance_of\
        AssLauncher::Enterprise::Ole::WpConnection
      ib.ole(:sagent).must_be_instance_of\
        AssLauncher::Enterprise::Ole::AgentConnection
      ib.ole(:thin).must_be_instance_of\
        AssLauncher::Enterprise::Ole::ThinApplication
      ib.ole(:thick).must_be_instance_of\
        AssLauncher::Enterprise::Ole::ThickApplication
      proc {
        ib.ole(:bad_ole)
      }.must_raise ArgumentError
    end

    it '#ole_requirement' do
      ib.send(:ole_requirement).must_equal "= #{ib.thick.version}"
    end

    it '#fail_if_not_exists not fail' do
      ib.expects(:exists?).returns(true)
      assert_nil ib.send(:fail_if_not_exists)
    end

    it '#fail_if_not_exists fail' do
      ib.expects(:exists?).returns(false)
      e = proc {
        ib.send :fail_if_not_exists
      }.must_raise RuntimeError
      e.message.must_match %r{Infobase not exists}i
    end

    it '#common_args' do
      ib.locale = 'locale_value'
      ib.unlock_code = 'unlock_code'
      ib.common_args.must_equal ['/L', 'locale_value', '/UC', 'unlock_code']
    end

    it '#command fail invalid client' do
      ib.expects(:fail_if_not_exists)
      e = proc {
        ib.send(:command, :bad_client, '')
      }.must_raise ArgumentError
      e.message.must_match %r{Invalid client}
    end

    it '#command :thick mocked' do
      zonde = {}
      cs = mock
      cs.expects(:to_args).returns([1,2])
      thick = mock
      thick.expects(:command).with(:mode, [1,2,3,4]).yields(zonde)
        .returns(:command)
      ib.expects(:fail_if_not_exists)
      ib.expects(:connection_string).returns(cs)
      ib.expects(:common_args).returns([3,4])
      ib.expects(:thick).returns(thick)
      ib.send(:command, :thick, :mode) do |z|
        z[:called] = true
      end.must_equal :command
      zonde[:called].must_equal true
    end

    it '#command :thin mocked' do
      zonde = {}
      cs = mock
      cs.expects(:to_args).returns([1,2])
      thin = mock
      thin.expects(:command).with([1,2,3,4]).yields(zonde)
        .returns(:command)
      ib.expects(:fail_if_not_exists)
      ib.expects(:connection_string).returns(cs)
      ib.expects(:common_args).returns([3,4])
      ib.expects(:thin).returns(thin)
      ib.send(:command, :thin, :mode) do |z|
        z[:called] = true
      end.must_equal :command
      zonde[:called].must_equal true
    end

    it '#command smoky' do
      ib.expects(:exists?).returns(true)
      ib.connection_string.expects(:to_args).returns([])
      cmd = ib.send(:command, :thick, :designer)
      cmd.must_be_instance_of AssLauncher::Support::Shell::Command
      cmd.args[0].must_equal 'DESIGNER'
    end

    it '#designer mocked' do
      zonde = {}
      ib.expects(:command).with(:thick, :designer).yields(zonde)
        .returns(:command)
      ib.designer do |z|
        z[:called] = true
      end.must_equal :command
      zonde[:called].must_equal true
    end

    it '#enterprise mocked' do
      zonde = {}
      ib.expects(:command).with(:client, :enterprise).yields(zonde)
        .returns(:command)
      ib.enterprise(:client) do |z|
        z[:called] = true
      end.must_equal :command
      zonde[:called].must_equal true
    end

    AssMaintainer::InfoBase::Interfaces::InfoBase.instance_methods.each do |m|
      it "##{m} must be implemented" do
        ib.must_respond_to m
        assert ib.method(m).owner.equal?(@ib_type_extension)
      end
    end

    it 'AssMaintainer::InfoBase include Interfaces::InfoBase' do
      AssMaintainer::InfoBase
        .include?(AssMaintainer::InfoBase::Interfaces::InfoBase)
        .must_equal true
    end
  end

  describe AssMaintainer::InfoBase do
    describe '.build_options_wrapper' do
      describe AssMaintainer::InfoBase::HOOKS do
        include FileBaseMaker

        desc.each do |hook, block|
          it "HOOKS generates attr_reader: ##{hook}" do
            assert_nil ib.send(hook).call(ib)
          end

          it "HOOKS didn't generates attr_writer ##{hook}=" do
            refute ib.respond_to? "#{hook}=".to_sym
          end
        end
      end

      describe AssMaintainer::InfoBase::ARGUMENTS do
        include FileBaseMaker
        desc.each do |hook, block|
          it "ARGUMENTS generates attr_accessor :#{hook}" do
            ib.send("#{hook}=", :new_value).must_equal :new_value
            ib.send(hook).must_equal :new_value
          end
        end
      end
    end

    describe '#initialize' do
      describe '#initialize with options' do
        hooks = {
          before_make: ->(ib) { :before_make },
          after_make: ->(ib) { :after_make },
          before_rm: ->(ib) { :before_rm },
          after_rm: ->(ib) { :after_rm }
        }

        workers = {
          maker: :maker,
          destroyer: :destroyer
        }

        arguments = {
          platform_require: :platform_require,
          sagent_host: :sagent_host,
          sagent_port: :sagent_port,
          sagent_usr: :sagent_usr,
          sagent_pwd: :sagent_pwd,
          cluster_usr: :cluster_usr,
          cluster_pwd: :cluster_pwd,
          unlock_code: :unlock_code
        }

        ib = AssMaintainer::InfoBase
          .new('name', Tmp::FILE_IB_CS, **hooks.merge(workers).merge(arguments))

        hooks.keys.each do |hook|
          it "hook #{hook}" do
            ib.send(hook).call(ib).must_equal hook
          end
        end

        workers.keys.each do |w|
          it "worker #{w}" do
            ib.send(w).must_equal w
          end
        end

        arguments.keys.each do |a|
          it "argument #{a}" do
            ib.send(a).must_equal a
          end
        end
      end

      it '#initialize with block' do
        zonde = {}
        AssMaintainer::InfoBase.new('name', Tmp::FILE_IB_CS) do |ib|
          zonde[:called] = true
          ib.name.must_equal 'name'
        end
        zonde[:called].must_equal true
      end

      it '#initialize fail' do
        proc {
          AssMaintainer::InfoBase.new('name', 'ws="example.com"')
        }.must_raise ArgumentError
      end
    end

    describe 'as :server type' do
      include CommonInfobaseTests
      attr_reader :ib
      before do
        @ib_type_extension = AssMaintainer::InfoBase::ServerIb
        @cs_class = AssLauncher::Support::ConnectionString::Server
        @ib = AssMaintainer::InfoBase.new('srv_tmp', Tmp::SRV_IB_CS, false)
      end

      it 'instance must extended by InfoBase::ServerIb' do
        ib.singleton_class
          .include?(@ib_type_extension).must_equal true
      end
    end

    describe 'as :file type' do
      attr_reader :ib
      include CommonInfobaseTests
      before do
        @ib_type_extension = AssMaintainer::InfoBase::FileIb
        @cs_class = AssLauncher::Support::ConnectionString::File
        @ib = AssMaintainer::InfoBase.new('tmp', Tmp::FILE_IB_CS, false)
        @ib.rm! :yes if ib.exists?
      end

      it 'instance must extended by InfoBase::FileIb' do
        ib.singleton_class
          .include?(@ib_type_extension).must_equal true
      end
    end

    describe 'as read only infobase' do
      attr_reader :ib
      before do
        @ib = AssMaintainer::InfoBase.new('tmp', Tmp::FILE_IB_CS)
        @ib.instance_eval do
          def exists?
            true
          end
        end
      end

      it '#rm!' do
        proc {
          ib.rm! :yes
        }.must_raise AssMaintainer::InfoBase::MethodDenied
      end

      it '#make' do
        ib.expects(:exists?).returns(false)
        proc {
          ib.make
        }.must_raise AssMaintainer::InfoBase::MethodDenied
      end

      it '#restore!' do
        proc {
          ib.restore! ''
        }.must_raise AssMaintainer::InfoBase::MethodDenied
      end

      it '#cfg.load_xml' do
        proc {
          ib.cfg.load_xml ''
        }.must_raise AssMaintainer::InfoBase::MethodDenied
      end

      it '#cfg.load' do
        proc {
          ib.cfg.load ''
        }.must_raise AssMaintainer::InfoBase::MethodDenied
      end

      it '#db_cfg.upadte' do
        proc {
          ib.db_cfg.update
        }.must_raise AssMaintainer::InfoBase::MethodDenied
      end
    end
  end

  describe AssMaintainer::InfoBase::DefaultMaker do
    it 'FIXME' do
      skip 'FIXME'
    end
  end
end
