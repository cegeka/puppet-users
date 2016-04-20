require 'spec_helper_acceptance'

describe 'users::localgroup' do

  describe 'running puppet code' do
    it 'should work with no errors' do
      pp = <<-EOS
        users::localgroup { 'foo':
          gid => '10001'
        }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

    describe file '/etc/group' do
      it { is_expected.to be_file }
      its(:content) { should contain /foo/ }
    end

  end
end

