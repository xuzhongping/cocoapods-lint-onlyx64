require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Onlyx64 do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w{ onlyx64 }).should.be.instance_of Command::Onlyx64
      end
    end
  end
end

