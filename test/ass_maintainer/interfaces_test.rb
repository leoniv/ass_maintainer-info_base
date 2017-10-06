require 'test_helper'

module AssMaintainer::InfoBaseTest
  describe AssMaintainer::InfoBase::Interfaces::InfoBaseWrapper do
    include desc
    desc.instance_methods.each do |m|
      it "#{m}" do
        proc {
          send m
        }.must_raise NotImplementedError
      end
    end
  end

  describe AssMaintainer::InfoBase::Interfaces::IbMaker do
    include desc
    abstracts = [:entry_point]
    abstracts.each do |m|
      it "#{m}" do
        proc {
          send m
        }.must_raise NotImplementedError
      end
    end

    it '#execute' do
      expects(:entry_point)
      execute(:infobase)
      infobase.must_equal(:infobase)
    end
  end

  describe AssMaintainer::InfoBase::Interfaces::IbDestroyer do
    include desc
    abstracts = [:entry_point]
    abstracts.each do |m|
      it "#{m}" do
        proc {
          send m
        }.must_raise NotImplementedError
      end
    end

    it '#execute' do
      expects(:entry_point)
      execute(:infobase)
      infobase.must_equal(:infobase)
    end
  end
end
