module AssMaintainer::InfoBaseTest
  # Mixin foor parsing 1C:Enterprise server environment
  # Pass environment via $ESRV_ENV like:
  # ```
  # $ export ESRV_ENV="--ragent user:pass@host:port \
  #   --rmngr user:pass@host:port \
  #   --dbms MSSQLServer \
  #   --dbsrv user:pass@localhost\\sqlexpress"
  # ```
  module EsrvEnv
    require 'clamp'
    require 'shellwords'

    ESRV_ENV = 'ESRV_ENV'

    class Parser < Clamp::Command

      # Parse string like +user:password@host:port+
      # @param s [String]
      # @return [Array] ['host:port', 'user', 'password']
      def parse_srv_str(s)
        fail ArgumentError, 'argument require' if s.to_s.empty?

        split = s.split('@')
        fail ArgumentError, "ivalid argument `#{s}'" if split.size > 2

        host = split.pop
        return [host, nil, nil] if split.size.zero?

        split = split[0].split(':')
        fail ArgumentError, "ivalid argument `#{s}'" if split.size > 2

        user = split.shift
        pass = split.shift

        [host, user, pass]
      end

      attr_reader :sagent_host, :sagent_port, :sagent_usr, :sagent_pwd
      def parse_ragent(s)
        host, @sagent_usr, @sagent_pwd = parse_srv_str(s)
        @sagent_host, @sagent_port = host.split(':')
      end

      option '--ragent', 'user:pass@ragent_host:port', '1C:Eneterprise server', required: true do |s|
        parse_ragent(s)
        s
      end

      attr_reader :cluster_usr, :cluster_pwd, :cluster_host, :cluster_port
      def parse_rmngr(s)
        host, @cluster_usr, @cluster_pwd = parse_srv_str(s)
        @cluster_host, @cluster_port = host.split(':')
      end

      option '--rmngr', 'user:pass@rmngr_host:port', '1C:Eneterprise cluster', required: true do |s|
        parse_rmngr(s)
        s
      end

      def self.dbms_values
        AssLauncher::Support::ConnectionString::DBMS_VALUES
      end

      def dbms_values
        self.class.dbms_values
      end

      option '--dbms', 'DBMS_TYPE', "dbms types: #{dbms_values}", required: true do |s|
        raise ArgumentError, "valid values: #{dbms_values}" unless dbms_values.include? s
        s
      end

      attr_reader :dbsrv_usr, :dbsrv_pwd, :dbsrv_host
      option '--dbsrv', 'user:pass@host', 'DB server', required: true do |s|
        @dbsrv_host, @dbsrv_usr, @dbsrv_pwd = parse_srv_str(s)
        s
      end

      def execute; end
    end

    def help_message
      "$export #{ESRV_ENV}=\"--ragent user:pass@host:port \\\n"\
      "  --rmngr user:pass@host:port \\\n"\
      "  --dbms MSSQLServer \\\n"\
      '  --dbsrv user:pass@localhost\\\\sqlexpress"'
    end

    def esrv_env
      skip 'You must passes server environment via'\
        " environment variable `#{ESRV_ENV}' for example:\n#{help_message}" if\
        ENV[ESRV_ENV].to_s.empty?
      ENV[ESRV_ENV]
    end

    def esrv_argv
      Shellwords.shellsplit(esrv_env.gsub('\\','\\\\\\'))
    end

    def env_parser
      @env_parser ||= env_parser_get
    end

    def env_parser_get
      p = env_parser_new
      begin
        p.parse(esrv_argv)
      rescue Clamp::UsageError => e
        raise Clamp::UsageError
          .new("#{e.message}\n\nUsage `#{EsrvEnv::ESRV_ENV}' example:\n\n#{help_message}\n", '')
      end
      p
    end

    def env_parser_new
      Parser.new ''
    end
  end
end
