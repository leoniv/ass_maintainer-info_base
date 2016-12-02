module AssMaintainer
  class InfoBase
    # Default infobase maker
    class DefaultMaker
      include Interfaces::IbMaker
      # :hodoc:
      def entry_point
        infobase.thick
          .command(:createinfobase,
                   infobase.connection_string.createinfobase_args +
                   infobase.common_args)
          .run.wait.result.verify!
      end
    end
  end
end
