module AssMaintainer
  class InfoBase
    module ServerIb
      module EnterpriseServers
        # @api private
        # Mixins
        module Support
          # Mixin for redirect +method_missing+ to +ole+ object
          module SendToOle
            def method_missing(m, *args)
              ole.send m, *args
            end
          end

          # Ole runtime mixin
          module OleRuntime
            require 'ass_ole'
            # Close connection with 1C:Enterprise server
            def disconnect
              runtime_stop
            end

            # True if connected
            def connected?
              respond_to?(:ole_runtime_get) && ole_runtime_get.runned?
            end

            def runtime_stop
              ole_runtime_get.stop if respond_to? :ole_runtime_get
            end
            private :runtime_stop

            # Include and run {.runtime_new} runtime
            def runtime_run(host_port, platform_require)
              self.class.like_ole_runtime OleRuntime.runtime_new(self) unless\
                respond_to? :ole_runtime_get
              ole_runtime_get.run host_port, platform_require
            end
            private :runtime_run

            # Make new runtime module +AssOle::Runtimes::Claster::(Agent|Wp)+
            # for access to
            # +AssLauncher::Enterprise::Ole::(AgentConnection|WpConnection)+
            # @param inst [#runtime_type] +#runtime_type+ must returns
            #   +:wp+ or +:agent+ values
            # @return [Module]
            def self.runtime_new(inst)
              Module.new do
                is_ole_runtime inst.runtime_type
              end
            end

            def _connect(host_port, platform_require)
              runtime_run host_port, platform_require unless connected?
              begin
                authenticate unless authenticate?
              rescue
                runtime_stop
                raise
              end
              self
            end

            def authenticate
              fail 'Abstract method'
            end

            def authenticate?
              fail 'Abstract method'
            end
          end

          # Mixin for find infobase per name
          module InfoBaseFind
            def infobases
              fail 'Abstract method'
            end

            # Searching infobase in {#infobases} array
            # @param ib_name [String] infobase name
            # @return [WIN32OLE] +IInfoBaseShort+ ole object
            # @raise (see #infobases)
            def infobase_find(ib_name)
              infobases.find do |ib|
                ib.Name.upcase == ib_name.upcase
              end
            end

            # True if infobase registred in cluster
            # @param ib_name [String] infobase name
            # @raise (see #infobase_find)
            def infobase_include?(ib_name)
              !infobase_find(ib_name).nil?
            end
          end

          # Mixin for reconnect ole runtime
          module Reconnect
            def reconnect
              fail "Serevice #{host_port} not"\
                " available: #{tcp_ping.exception}" unless ping?
              return unless reconnect_required?
              ole_connector.__close__
              ole_connector.__open__ host_port
            end
            private :reconnect

            def reconnect_required?
              return true unless ole_connector.__opened__?
              begin
                _reconnect_required?
              rescue WIN32OLERuntimeError => e
                return true if e.message =~ %r{descr=10054}
              end
            end
            private :reconnect_required?

            def _reconnect_required?
              fail 'Abstract method'
            end
            private :_reconnect_required?
          end

          # @api private
          # Abstract server connection.
          # Mixin for {Cluster} and {ServerAgent}
          module ServerConnection
            # Server user name
            # See {#initialize} +user+ argument.
            # @return [String]
            attr_accessor :user

            # Server user password
            # See {#initialize} +password+ argument.
            # @return [String]
            attr_accessor :password

            # Host name
            attr_accessor :host

            # TCP port
            attr_accessor :port

            # @param host_port [String] string like a +host_name:port_number+
            # @param user [String] server user name
            # @param password [String] serever user password
            def initialize(host_port, user = nil, password = nil)
              fail ArgumentError, 'Host name require' if host_port.to_s.empty?
              @raw_host_port = host_port
              @host = parse_host
              @port = parse_port || default_port
              @user = user
              @password = password
            end

            # String like a +host_name:port_number+.
            # @return [String]
            def host_port
              "#{host}:#{port}"
            end

            def parse_port
              p = @raw_host_port.split(':')[1].to_s.strip
              return p unless p.empty?
            end
            private :parse_port

            def parse_host
              p = @raw_host_port.split(':')[0].to_s.strip
              fail ArgumentError, "Invalid host_name for `#{@raw_host_port}'" if\
                p.empty?
              p
            end
            private :parse_host

            def default_port
              fail 'Abstract method'
            end

            # Return +true+ if TCP port available on server
            def ping?
              tcp_ping.ping?
            end

            require 'net/ping/tcp'
            # @return [Net::Ping::TCP] instance
            def tcp_ping
              @tcp_ping ||= Net::Ping::TCP.new(host, port)
            end

            def eql?(other)
              host.upcase == other.host.upcase && port == other.port
            end
            alias_method :==, :eql?
          end
        end
      end
    end
  end
end
