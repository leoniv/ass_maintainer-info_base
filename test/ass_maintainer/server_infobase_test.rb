require 'test_helper'

module AssMaintainer::InfoBaseTest
  describe AssMaintainer::InfoBase::ServerIb do
    attr_reader :server_ib
    def server_ib(infobase_wrapper = nil)
      @server_ib ||= Class.new(AssMaintainer::InfoBase) do
        def initialize(infobase_wrapper)
          super '', 'srvr="fake_server";ref="fake_ref"'
          @infobase_wrapper = infobase_wrapper
        end
      end.new(infobase_wrapper)
    end

    def infobase_wrapper_stub(ib = nil)
      AssMaintainer::InfoBase::ServerIb::InfoBaseWrapper.new(ib)
    end

    it '#exists? true' do
      ib_wrapper = infobase_wrapper_stub
      ib_wrapper.expects(:clusters).returns([1,2,3])
      server_ib(ib_wrapper).exists?.must_equal true
    end

    it '#exists? false' do
      ib_wrapper = infobase_wrapper_stub
      ib_wrapper.expects(:clusters).returns([])
      server_ib(ib_wrapper).exists?.must_equal false
    end

    it '#wp_connection' do
      ib_wrapper = infobase_wrapper_stub
      ib_wrapper.expects(:wp_connection).returns(:wp_connection)
      server_ib(ib_wrapper).send(:wp_connection).must_equal :wp_connection
    end

    def session_wrapper_stub(app_id)
      Class.new(AssMaintainer::InfoBase::ServerIb::\
                EnterpriseServers::Wrappers::Session) do
        attr_reader :SessionId, :AppId, :Host, :UserName
        def initialize(app_id)
          @SessionId = 0
          @AppId = app_id
          @Host = ''
          @UserName = ''
        end
      end.new(app_id)
    end

    def all_sessions
      %w{SrvrConsole FakeApp1 FakeApp2}.map do |app|
        session_wrapper_stub(app)
      end
    end

    it '#sessions' do
      wrapper = infobase_wrapper_stub
      wrapper.expects(:sessions).returns(all_sessions)
      server_ib(wrapper).sessions.map {|s| s.app_id}.must_equal %w{FakeApp1 FakeApp2}
    end

    it '#lock fail LockError' do
      server_ib.unlock_code.to_s.must_equal ''
      e = proc {
        server_ib.lock
      }.must_raise AssMaintainer::InfoBase::LockError

      e.message.must_match %r{unlock_code is required}
    end

    def wp_connection_stub
      r = mock
      r.responds_like(AssMaintainer::InfoBase::ServerIb::EnterpriseServers::\
                      WpConnection.new(nil))
      r
    end

    def session_mock
      r = mock
      r.responds_like(AssMaintainer::InfoBase::Session
        .new(nil, nil, nil, nil, nil))
      r
    end

    it '#lock' do
      wp_connection = wp_connection_stub
      wp_connection.expects(:lock_sessions!).with(:from, :to, :uc, :mess)
      sess = session_mock
      sess.expects(:terminate).times(3)
      server_ib.expects(:unlock_code).returns(:uc).twice
      server_ib.expects(:unlock)
      server_ib.expects(:wp_connection).returns(wp_connection)
      server_ib.expects(:lock_schjobs)
      server_ib.expects(:sessions).returns([sess, sess, sess])
      server_ib.lock(from: :from, to: :to, message: :mess).must_be_nil
    end

    it '#unlock' do
      wp_connection = wp_connection_stub
      wp_connection
        .expects("raise_unless_unlock_possable")
        .with(AssMaintainer::InfoBase::UnlockError, :uc)
      server_ib.expects(:unlock_code).returns(:uc)
      server_ib.expects(:wp_connection).returns(wp_connection)
      server_ib.expects(:unlock!)
      server_ib.unlock.must_be_nil
    end

    it '#unlock!' do
      wp_connection = wp_connection_stub
      wp_connection.expects(:unlock_sessions!)
      wp_connection.expects(:unlock_schjobs!)
      server_ib.expects(:wp_connection).returns(wp_connection).twice
      server_ib.unlock!.must_be_nil
    end

    it '#lock_schjobs' do
      wp_connection = wp_connection_stub
      wp_connection.expects(:lock_schjobs!)
      server_ib.expects(:wp_connection).returns(wp_connection)
      server_ib.lock_schjobs.must_be_nil
    end

    it '#lock_schjobs' do
      wp_connection = wp_connection_stub
      wp_connection.expects(:unlock_schjobs!)
      server_ib.expects(:wp_connection).returns(wp_connection)
      server_ib.unlock_schjobs.must_be_nil
    end

    it '#locked?' do
      wp_connection = wp_connection_stub
      wp_connection.expects(:locked?).returns(:locked?)
      server_ib.expects(:wp_connection).returns(wp_connection)
      server_ib.locked?.must_equal :locked?
    end
  end

  describe AssMaintainer::InfoBase::Session do
    it '#initialize' do
      inst = AssMaintainer::InfoBase::Session.new(:id, :app_id, :host, :user, :infobase)
      inst.id.must_equal :id
      inst.app_id.must_equal :app_id
      inst.host.must_equal :host
      inst.user.must_equal :user
      inst.infobase.must_equal :infobase
    end

    def ib_stub
      mock
    end

    def infobase_wrapper_stub
      r = mock
      r.responds_like AssMaintainer::InfoBase::ServerIb::InfoBaseWrapper.new(nil)
      r
    end

    it '#terminate unless terminated?' do
      inst = AssMaintainer::InfoBase::Session.new(nil, nil, nil, nil, ib_stub)
      wrapper = infobase_wrapper_stub
      wrapper.expects(:terminate).with(inst).returns(:term)
      inst.infobase.expects(:infobase_wrapper).returns(wrapper)
      inst.expects(:terminated?).returns(false)
      inst.terminate.must_equal :term
    end

    it '#terminate if terminated?' do
      inst = AssMaintainer::InfoBase::Session.new(nil, nil, nil, nil, ib_stub)
      inst.infobase.expects(:infobase_wrapper).never
      inst.expects(:terminated?).returns(true)
      inst.terminate.must_be_nil
    end

    it 'terminated? true' do
      inst = AssMaintainer::InfoBase::Session.new(:id, nil, nil, nil, ib_stub)
      wrapper = infobase_wrapper_stub
      wrapper.expects(:session_get).with(:id).returns([])
      inst.infobase.expects(:infobase_wrapper).returns(wrapper)
      inst.terminated?.must_equal true
    end

    it 'terminated? true' do
      inst = AssMaintainer::InfoBase::Session.new(:id, nil, nil, nil, ib_stub)
      wrapper = infobase_wrapper_stub
      wrapper.expects(:session_get).with(:id).returns([1])
      inst.infobase.expects(:infobase_wrapper).returns(wrapper)
      inst.terminated?.must_equal false
    end
  end

  describe AssMaintainer::InfoBase::ServerIb::ServerBaseMaker do
    def maker(ib = nil)
      @maker ||= (
        r = self.class.desc.new
        r.instance_variable_set(:@infobase, ib)
        r
      )
    end

    it 'const REQUIRE_FIELDS = [:dbsrvr, :dbuid, :dbms]' do
      AssMaintainer::InfoBase::ServerIb::ServerBaseMaker::\
        REQUIRE_FIELDS.must_equal [:dbsrvr, :dbuid, :dbms]
    end

    it '#entry_point' do
      maker.class.superclass.must_equal AssMaintainer::InfoBase::DefaultMaker
      AssMaintainer::InfoBase::DefaultMaker
        .any_instance.expects(:entry_point).returns(:entry_point)
      maker.expects(:prepare_making)
      maker.execute(nil).must_equal :entry_point
    end

    def ib_stub(cs = nil)
      @ib_stub ||= AssMaintainer::InfoBase.new('', cs)
    end

    it '#connection_string' do
      cs = 'Srvr="fake_host";Ref="fake.ib";'
      maker(ib_stub(cs)).connection_string.to_s.must_equal cs
    end

    it '#require_filled? false without :dbsrvr' do
      cs = 'Srvr="fake_host";Ref="fake_ib";DBMS="MSSQLServer";dbuid="dbusr"'
      maker(ib_stub(cs)).require_filled?.must_equal false
    end

    it '#require_filled? false without :dbms' do
      cs = 'Srvr="fake_host";Ref="fake_ib";dbsrvr="db_fake_host";dbuid="dbusr"'
      maker(ib_stub(cs)).require_filled?.must_equal false
    end

    it '#require_filled? false without :dbuid' do
      cs = 'Srvr="fake_host";Ref="fake_ib";DBMS="MSSQLServer";dbsrvr="db_fake_host"'
      maker(ib_stub(cs)).require_filled?.must_equal false
    end

    it '#require_filled? true' do
      cs = 'Srvr="fake_host";Ref="fake_ib";dbuid="dbusr";'\
        'DBMS="MSSQLServer";dbsrvr="db_fake_host"'
      maker(ib_stub(cs)).require_filled?.must_equal true
    end

    it '#set_if_empty' do
      cs = 'Srvr="fake_host";Ref="fake.ib";'
      maker(ib_stub(cs)).set_if_empty(:srvr, 'srvr').must_be_nil
      maker.connection_string.to_s.must_equal cs
      maker.set_if_empty(:db, 'db').must_equal 'db'
      maker.set_if_empty(:crsqldb, 'Y').must_equal 'Y'
      maker.set_if_empty(:susr, 'susr').must_equal 'susr'
      maker.set_if_empty(:spwd, 'spwd').must_equal 'spwd'

      maker.connection_string
        .to_s.must_equal 'Srvr="fake_host";Ref="fake.ib";DB="db"'\
                         ';CrSQLDB="Y";SUsr="susr";SPwd="spwd";'
    end

    it '#prepare_making fail' do
      maker.expects(:require_filled?).returns(false)
      e = proc {
        maker.prepare_making
      }.must_raise RuntimeError

      e.message.must_match %r{Fields \[:dbsrvr, :dbuid, :dbms\] must be filled}
    end

    it '#prepare_making' do
      cs = 'Srvr="fake";Ref="fake";'
      ib_stub(cs).cluster_usr = :cusr
      ib_stub.cluster_pwd = :cpwd

      maker(ib_stub).expects(:require_filled?).returns(true)

      maker.connection_string.to_s.must_equal cs
      maker.prepare_making
      maker.connection_string.to_s
        .must_equal 'Srvr="fake";Ref="fake";DB="fake"'\
                    ';CrSQLDB="Y";SUsr="cusr";SPwd="cpwd";'
    end
  end

  describe AssMaintainer::InfoBase::ServerIb::ServerBaseDestroyer do
    def infobase_wrapper_stub
      r = mock
      r.responds_like AssMaintainer::InfoBase::ServerIb::InfoBaseWrapper.new(nil)
      r
    end

    it '#entry_point' do
      wrapper = infobase_wrapper_stub
      wrapper.expects(:drop_infobase!).with(:destroy_db).returns(:drop)
      ib_mock = mock
      ib_mock.expects(:infobase_wrapper).returns(wrapper)
      destroyer = self.class.desc.new
      destroyer.expects(:infobase).returns(ib_mock)
      destroyer.execute(nil).must_equal :drop
    end

    it 'const DROP_MODE = :destroy_db' do
      AssMaintainer::InfoBase::ServerIb::ServerBaseDestroyer::DROP_MODE
        .must_equal :destroy_db
      AssMaintainer::InfoBase::ServerIb::EnterpriseServers::\
        WpConnection::DROP_MODES[:destroy_db].wont_be_nil
    end
  end

  describe AssMaintainer::InfoBase::ServerIb::InfoBaseWrapper do
    def new_wrapper(infobase = nil)
      self.class.desc.new infobase
    end

    it '#exists? not implemented' do
      raise 'FIXME'
    end

    it '#initialize' do
      w = new_wrapper(:infobase)
      w.infobase.must_equal :infobase
    end
  end

  describe AssMaintainer::InfoBase::ServerIb::EnterpriseServers::Support::ServerConnection do
    before do
      @inst = Class.new do
        include AssMaintainer::InfoBase::ServerIb::EnterpriseServers::Support::ServerConnection
      end.new 'fake_host:fake_port', 'user_name', 'password'
    end

    it '#initialize' do
      @inst.host_port.must_equal 'fake_host:fake_port'
      @inst.user.must_equal 'user_name'
      @inst.password.must_equal 'password'
    end

    it '#host' do
      @inst.host.must_equal 'fake_host'
    end

    it '#port' do
      @inst.port.must_equal 'fake_port'
    end

    it '#tcp_ping' do
      @inst.tcp_ping.must_be_instance_of Net::Ping::TCP
      @inst.tcp_ping.host.must_equal 'fake_host'
      @inst.tcp_ping.port.must_equal 'fake_port'
    end

    it '#ping?' do
      fake_ping = mock
      fake_ping.expects(:ping?).returns(:true_false)
      @inst.expects(:tcp_ping).returns(fake_ping)
      @inst.ping?.must_equal :true_false
    end
  end

  describe AssMaintainer::InfoBase::Session do
    it 'FIXME' do
      skip 'FIXME'
    end
  end
end
