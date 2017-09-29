require 'test_helper'

module AssMaintainer::InfoBaseTest
  describe EsrvEnv do
    include EsrvEnv

    def ch_esrv_env(val, &test)
      old = ENV[EsrvEnv::ESRV_ENV]
      ENV[EsrvEnv::ESRV_ENV] = val
      test.call
    ensure
      ENV[EsrvEnv::ESRV_ENV] = old
    end

    EXP_ESRV_ENV = {
      ragent: '--ragent rusr:rpwd@rhost:999',
      rmngr: '--rmngr musr:mpwd@mhost:666',
      dbms: '--dbms MSSQLServer',
      dbsrv: '--dbsrv dusr:dpwd@dbhost:port'
    }.freeze

    describe EsrvEnv::Parser do
      require 'shellwords'

      def parser(cmd = EXP_ESRV_ENV.values.join(' '))
        @parser = EsrvEnv::Parser.new('')
        @parser.parse Shellwords.shellsplit(cmd)
        @parser
      end

      it 'parse --ragent fail' do
        e = proc {
          parser('--ragent')
        }.must_raise Clamp::UsageError
        e.message.must_match %r{argument require}
      end

      it 'parse --rmngr fail' do
        e = proc {
          parser('--rmngr')
        }.must_raise Clamp::UsageError
        e.message.must_match %r{argument require}
      end

      it 'parse --dbsrv fail' do
        e = proc {
          parser('--dbsrv')
        }.must_raise Clamp::UsageError
        e.message.must_match %r{argument require}
      end

      it 'parse --dbms fail' do
        e = proc {
          parser('--dbms')
        }.must_raise Clamp::UsageError
        e.message.must_match %r{valid values}
      end

      it 'fail if --dbms wrong argument' do
        cmd = EXP_ESRV_ENV.dup
        cmd[:dbms] = '--dbms wrong_argument'

        ch_esrv_env(cmd.values.join(' ')) do
          e = proc {
            env_parser
          }.must_raise Clamp::UsageError
          e.message.must_match %r{valid values:}i
        end
      end

      it 'parse --ragent' do
        parser.sagent_usr.must_equal 'rusr'
        parser.sagent_pwd.must_equal 'rpwd'
        parser.sagent_host.must_equal 'rhost'
        parser.sagent_port.must_equal '999'
      end

      it 'parse --rmngr' do
        parser.cluster_usr.must_equal 'musr'
        parser.cluster_pwd.must_equal 'mpwd'
        parser.cluster_host.must_equal 'mhost'
        parser.cluster_port.must_equal '666'
      end

      it 'parse --dbsrv' do
        parser.dbsrv_usr.must_equal 'dusr'
        parser.dbsrv_pwd.must_equal 'dpwd'
        parser.dbsrv_host.must_equal 'dbhost:port'
      end

      it 'parse --dbms' do
        parser.dbms.must_equal 'MSSQLServer'
      end
    end

    describe '#env_parser' do
      it "returns EsrvEnv::Parser" do
        ch_esrv_env(EXP_ESRV_ENV.values.join(' ')) do
          env_parser.must_be_instance_of EsrvEnv::Parser
        end
      end

      def _env_cmd(*keys)
        keys.each_with_object(Hash.new(nil)) {|i,o| o[i] = EXP_ESRV_ENV[i]}
          .values.join(' ')
      end

      it 'skip if $ESRV_ENV not set' do
        ch_esrv_env(nil) do
          e = proc {
            env_parser
          }.must_raise Minitest::Skip
          e.message.must_match %r{You must passes.+via.+`ESRV_ENV'.+--dbsrv user:pass}mi
        end
      end

      it 'fail if --ragent not passed' do
        ch_esrv_env(_env_cmd(:rmngr, :dbms, :dbsrv)) do
          e = proc {
            env_parser
          }.must_raise Clamp::UsageError
          e.message.must_match %r{option '--ragent' is required}
        end
      end

      it 'fail if --rmngr not passed' do
        ch_esrv_env(_env_cmd(:ragent, :dbms, :dbsrv)) do
          e = proc {
            env_parser
          }.must_raise Clamp::UsageError
          e.message.must_match %r{option '--rmngr' is required}
        end
      end

      it 'fail if --dbsrv not passed' do
        ch_esrv_env(_env_cmd(:ragent, :rmngr, :dbms)) do
          e = proc {
            env_parser
          }.must_raise Clamp::UsageError
          e.message.must_match %r{option '--dbsrv' is required}
        end
      end

      it 'fail if --dbms not passed' do
        ch_esrv_env(_env_cmd(:ragent, :rmngr, :dbsrv)) do
          e = proc {
            env_parser
          }.must_raise Clamp::UsageError
          e.message.must_match %r{option '--dbms' is required}
        end
      end
    end
  end
end
