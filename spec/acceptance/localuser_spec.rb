require 'spec_helper_acceptance'

describe 'users::localuser' do

  describe 'running puppet code' do
    it 'should work with no errors' do
      pp = <<-EOS
        users::localgroup { 'foo':
          gid => '10001'
        }
        users::localuser { 'foo':
          uid => '10001',
          logingroup => 'foo'
        }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

    describe file '/etc/passwd' do
      it { is_expected.to be_file }
      its(:content) { should contain /foo/ }
    end

  end
end

