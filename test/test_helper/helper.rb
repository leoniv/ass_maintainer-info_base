module AssMaintainer::InfoBaseTest
  module Helper
    require 'ass_launcher'
    extend AssLauncher::Api
    extend AssLauncher::Support::Platforms

    AssLauncher::Support::Platforms.private_instance_methods.each do |m|
      public_class_method m
    end
  end
end
