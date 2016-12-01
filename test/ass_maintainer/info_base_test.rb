require 'test_helper'

module AssMaintainer::InfoBaseTest
  describe AssMaintainer::InfoBase::VERSION do
    it 'VERSION setted' do
      ::AssMaintainer::InfoBase::VERSION.wont_equal nil
    end
  end

  module CommonInfobase
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
      ib.expects(:make_infobase!).returns(:ib)
      ib.make.must_equal ib
    end

    it '#make not exists infobase' do
      seq = sequence('sec')
      hook = mock
      hook.expects(:call).with(ib).twice
      maker = mock
      maker.expects(:execute).with(ib)
      ib.expects(:exists?).returns(false)
      ib.expects(:make_infobase!)
      ib.expects(:read_only?).in_sequence(seq).returns(false)
      ib.expects(:before_make).in_sequence(seq).returns(hook)
      ib.expects(:maker).in_sequence(seq).returns(maker)
      ib.expects(:after_make).in_sequence(seq).returns(hook)
      ib.make.must_equal ib
    end

    it '#maker' do
      ib.send(:maker).must_be_instance_of AssMaintainer::InfoBase::DefaultMaker
      ib.options[:maker] = :fake_maiker
      ib.send(:maker).must_equal :fake_maiker
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
     ib.rm!(:yes).must_equal nil
    end

    it '#rm! exists infobase' do
      seq = sequence('sec')
      hook = mock
      hook.expects(:call).with(ib).twice
      destroyer = mock
      destroyer.expects(:execute).with(ib)
      ib.expects(:exists?).returns(true)
      ib.expects(:make_infobase!)
      ib.expects(:read_only?).in_sequence(seq).returns(false)
      ib.expects(:before_rm).in_sequence(seq).returns(hook)
      ib.expects(:destroyer).in_sequence(seq).returns(destroyer)
      ib.expects(:after_rm).in_sequence(seq).returns(hook)
      ib.rm!(:yes).must_equal nil
    end

    it '#destroyer default' do
      ib.send(:destroyer).must_be_instance_of @destroyer_class
    end

    it '#destroyer custom' do
      ib.options[:destroyer] = :fake_destroyer
      ib.send(:destroyer).must_equal :fake_destroyer
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
      skip
      cs = mock
      cs.expects(:usr=).with(:usr_value).returns(:usr_value)
      ib.expects(:connection_string).returns(cs)
      ib.usr=(:usr_value).must_equal :usr_value
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
      skip
      cs = mock
      cs.expects(:pwd=).with(:pwd_value).returns(:pwd_value)
      ib.expects(:connection_string).returns(cs)
      ib.pwd=(:pwd_value).must_equal :pwd_value
    end

    it '#pwd and #pwd= smoky' do
      ib.pwd = :user_name
      ib.pwd.must_equal :user_name
    end
  end

  describe AssMaintainer::InfoBase do
    describe '#initialize' do
      it 'FIXME' do
        skip
      end
    end

    describe 'as :server type' do
      include CommonInfobase
      attr_reader :ib
      before do
        @cs_class = AssLauncher::Support::ConnectionString::Server
        @destroyer_class = AssMaintainer::InfoBase::ServerIb::ServerBaseDestroyer
        @ib = AssMaintainer::InfoBase.new('srv_tmp', Tmp::SRV_IB_CS, false)
        # FIXME: ib.rm! :yes
      end

    end

    describe 'as :file type' do
      attr_reader :ib
      include CommonInfobase
      before do
        @cs_class = AssLauncher::Support::ConnectionString::File
        @destroyer_class = AssMaintainer::InfoBase::FileIb::FileBaseDestroyer
        @ib = AssMaintainer::InfoBase.new('tmp', Tmp::FILE_IB_CS, false)
        @ib.rm! :yes if ib.exists?
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
        @ib.instance_eval do
          def exists?
            false
          end
        end
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
end
