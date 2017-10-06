require 'test_helper'

module AssMaintainer::InfoBaseTest
  describe AssMaintainer::InfoBase::ServerIb do
      attr_reader :server_ib
      before do
        @server_ib = Class.new(AssMaintainer::InfoBase) do
          def initialize
            super '', 'srvr="fake_server";ref="fake_ref"'
          end
        end.new
      end

      def infobase_wrapper_stub(ib = nil)
        AssMaintainer::InfoBase::ServerIb::InfoBaseWrapper.new(ib)
      end

      it '#exists?' do
        ib_wrapper = mock
        ib_wrapper.responds_like(infobase_wrapper_stub)
        ib_wrapper.expects(:exists?).returns(:i_dont_know)
        server_ib.expects(:infobase_wrapper).returns(ib_wrapper)
        server_ib.exists?.must_equal :i_dont_know
      end
  end

  describe AssMaintainer::InfoBase::ServerIb::ServerBaseMaker do
    it 'FIXME' do
      fail 'FIXME'
    end
  end

  describe AssMaintainer::InfoBase::ServerIb::ServerBaseDestroyer do
    it '#entry_point' do
      destroyer = self.class.desc.new
      raise 'FIXME'
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
end
