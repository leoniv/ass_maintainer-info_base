module AssMaintainer
  class InfoBase
    module Api
      def file(ib_name, &block)
        DSL.file(ib_name, &block)
      end

      def server(ib_name, &block)
        DSL.server(ib_name, &block)
      end

      def external(ib_name, connection_string, &block)
        DSL.external(ib_name, connection_string, &block)
      end
    end

  end
end
