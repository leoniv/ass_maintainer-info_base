module AssMaintainer
  class InfoBase
    module ServerIb
      require 'shellwords'
      require 'optparse'

      class ServerBaseDestroyer
        include Interfaces::IbDestroyer
        def entry_point
          fail NotImplementsError
        end
      end

      module Parser
        def options_help
          options.to_a
        end

        def opts
          @opts ||= OptionParser.new
        end

        def parse_str(str)
          parse Shellwords.shellwords(str)
        end

        def presult
          @presult ||= {}
        end
        private :presult
      end

      class ServerConnection
        extend Parser
        def self.options
          opts.on('-H', '--host HOST:PORT') do |v|
            presult[:host_port] = v
          end
          opts.on('-U', '--user [USER_NAME]') do |v|
            presult[:user] = v
          end
          opts.on('-P', '--password [PASSWORD]') do |v|
            presult[:password] = v
          end
          opts
        end

        def self.parse(argv)
          options.parse! argv
          new presult[:host_port], presult[:user], presult[:password]
        end

        attr_reader :host_port, :user, :password
        def initialize(host_port, user, password)
          fail ArgumentError, 'Host name require' if host_port.to_s.empty?
          @host_port = host_port.to_s
          @user = user
          @password = password
        end
      end

      class AgentConnection < ServerConnection; end

      class ClasterConnection < ServerConnection
        def fill_cs(cs)
          cs.srvr = host_port.to_s
          cs.susr = user
          cs.spwd = password
        end

        def to_connstr
          r = ""
          r << "Srvr=\"#{host_port}\";"
          r << "SUsr=\"#{user}\";" if user
          r << "SPwd=\"#{password}\";" if password
          r
        end
      end

      class DbConnection < ServerConnection
        def fill_cs(cs)
          cs.dbsrvr = host_port.to_s
          cs.dbuid = user
          cs.dbpwd = password
        end

        def to_connstr
          r = ""
          r << "DBSrvr=\"#{host_port}\";"
          r << "DBUID=\"#{user}\";" if user
          r << "DBPwd=\"#{password}\";" if password
          r
        end
      end

      class Db < DbConnection
        extend Parser
        def self.options
          opts = super
          opts.on("-D" ,"--dbms [#{AssLauncher::Support::ConnectionString::\
                  Server::DBMS_VALUES.join(' | ')}]",
                  'Type of DB for connection string') do |v|
            presult[:dbms] = v
          end
          opts.on('-N','--db-name [DBNAME]','Name of databse') do |v|
            presult[:name] = v
          end
          opts.on('-C','--create-db [Y|N]',
                  'Crate databse if not exists. Default Y') do |v|
            presult[:create_db] = v
          end
          opts
        end

        def self.parse(argv)
          options.parse! argv
          srv_conn = DbConnection.new(
            presult[:host_port], presult[:user], presult[:password])
          new presult[:name], srv_conn, presult[:dbms], presult[:create_db]
        end

        attr_reader :name, :srv_conn, :create_db, :dbms
        def initialize(name, srv_conn, dbms, create_db)
          fail ArgumentError, "DB name require" if name.to_s.empty?
          @name = name
          @srv_conn = srv_conn
          @dbms = dbms || fail(ArgumentError, "Require DBMS")
          @create_db = create_db || 'Y'
        end

        def fill_cs(cs)
          srv_conn.fill_cs(cs)
          cs.db = name
          cs.dbms = dbms
          cs.crsqldb = create_db
        end

        def to_connstr
          r = srv_conn.to_connstr
          r << "DB=\"#{name}\";"
          r << "DBMS=\"#{dbms}\";"
          r << "CrSQLDB=\"#{create_db}\";" if create_db
          r
        end
      end

    end
  end
end
