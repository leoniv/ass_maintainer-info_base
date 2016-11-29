require 'ass_tests/info_bases'

AssTests::InfoBases.describe do
  file :empty_ib do
  # DescribeOptions
    template nil # Путь к шаблону ИБ
    fixtures nil # Объект реализующий интрфейс AssTests::FixturesInterface для
     # заполнения ИБ
    maker nil # Объект реализующий интерфейс AssTests::IbMakerInterface создающий
     # ИБ
    destroyer nil # Объект реализующий интерфейс AssTests::IbDistroyerInterface
     # уничтожающий ИБ
    platform_require ENV['ASS_PLATFORM']
    before_make ->(ib) { puts "Before make #{ib.name}"}
    after_make ->(ib) { puts "After make #{ib.name}"}
    before_rm ->(ib) { puts "Before rm #{ib.name}"}
    after_rm ->(ib) { puts "After rm #{ib.name}"}
  # CommonDescriber
    locale nil
    user 'name'
    password 'password'
  # FileIb
    directory File.expand_path('../../tmp', __FILE__)
  end

  server :empty_server_ib do
  # DescribeOptions
    template nil
    fixtures nil
    maker nil
    destroyer nil
    platform_require '~> 8.3.8'
    before_make nil
    after_make nil
    before_rm nil
    after_rm nil
  # CommonDescriber
    locale nil
    user 'name'
    password 'password'
  # ServerIb
    agent ENV['ASS_SERVER_AGENT'] # --host 'host:port' --user 'admin' --password 'password'
    claster ENV['ASS_CLASTER'] # --host 'host:port' --user 'admin' --password 'password'
    # db ['EMPTY_DATA_BASE'] # --host 'host:port' --dbms 'MSSQLServer' --db-name 'db_name' --user 'admin' --password 'password' --create-db
    db "--host 'host:port' --dbms 'MSSQLServer' --db-name 'db_name' --user 'admin' --password 'password' --create-db"
    schjobdn # Запрет заданий см строка соединения
  end

  external :acc30, ENV['ACC30_IB_CONNECTION_STRING'] do
    platform_require '>= 8.3'
  end
end
