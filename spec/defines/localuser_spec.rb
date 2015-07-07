require 'spec_helper'

describe 'users::localuser' do
  context 'with an non-alphanumeric title' do
    let (:title) { 'foo bar' }
    let (:params) { {:logingroup => 'testgrp', :uid => '10001' } }

    it {
      expect { subject }.to raise_error(
        Puppet::Error, /namevar must be alphanumeric/
    )}
  end

  context 'with a non-alphabetic first character in the title' do
    let (:title) { '1foo' }
    let (:params) { {:logingroup => 'testgrp', :uid => '10001' } }

    it {
      expect { subject }.to raise_error(
        Puppet::Error, /namevar must be alphanumeric/
    )}
  end

  context 'with an alphanumeric title' do
    let (:title) { 'foo' }

    context 'and parameter uid unset' do
      let (:params) { {:logingroup => 'testgrp' } }

      it {
        expect { subject }.to raise_error(
          Puppet::Error, /parameter uid must be numeric/
      )}
    end

    context 'and parameter logingroup unset' do
      let (:params) { {:uid => '10001' } }

      it {
        expect { subject }.to raise_error(
          Puppet::Error, /parameter logingroup must be alphanumeric/
      )}
    end

    context 'and ensure => absent' do
      let (:params) { {:ensure => 'absent' } }

      it { should contain_user('foo').with(
        :ensure     => 'absent',
        :managehome => true
      )}

      it { should contain_file('/home/foo/bin').with(
        :ensure => 'absent',
        :before => 'User[foo]'
      )}
    end

    context 'and uid => foo' do
      let (:params) { {:uid => 'foo', :logingroup => 'testgrp' } }

      it {
        expect { subject }.to raise_error(
          Puppet::Error, /parameter uid must be numeric/
      )}
    end

    context 'and logingroup => 10001' do
      let (:params) { {:uid => '10001', :logingroup => '10001' } }

      it {
        expect { subject }.to raise_error(
          Puppet::Error, /parameter logingroup must be alphanumeric/
      )}
    end

    context 'and a non-alphabetic first character in the title' do
      let (:params) { {:uid => '10001', :logingroup => '1testgrp' } }

      it {
        expect { subject }.to raise_error(
          Puppet::Error, /parameter logingroup must be alphanumeric/
      )}
    end

    context 'and uid => 10001 and logingroup => testgroup' do
      context 'and ensure => stopped' do
        let (:params) { {:uid => '10001', :logingroup => 'testgrp', :ensure => 'stopped' } }

        it {
          expect { subject }.to raise_error(
            Puppet::Error, /parameter ensure must be present or absent/
          )}
      end

      context 'and managehome => string' do
        let (:params) { {:uid => '10001', :logingroup => 'testgrp', :managehome => 'string' } }

        it {
          expect { subject }.to raise_error(
            Puppet::Error, /parameter managehome must be a boolean/
          )}
      end

      context 'and default params' do
        let (:params) { {:uid => '10001', :logingroup => 'testgrp' } }

        it { should contain_user('foo').with(
          :uid        => '10001',
          :name       => 'foo',
          :gid        => 'testgrp',
          :ensure     => 'present',
          :managehome => true,
          :groups     => [],
          :password   => '!',
          :home       => '/home/foo',
          :shell      => '/bin/bash'
        )}

        it { should contain_file('/home/foo/bin').with(
          :ensure  => 'directory',
	  :owner   => '10001',
          :group   => 'testgrp'
        )}

        it { should_not contain_ssh_authorized_key('foo') }
      end

      context 'and sshkey => "ssh-rsa AAAAB3NzaC1yc2EAAAABI"' do
        let (:params) { {:uid => '10001', :logingroup => 'testgrp', :sshkey => 'ssh-rsa AAAAB3NzaC1yc2EAAAABI' } }

        it { should contain_user('foo').with(
          :uid        => '10001',
          :name       => 'foo',
          :gid        => 'testgrp',
          :ensure     => 'present',
          :comment    => '',
          :managehome => true,
          :groups     => [],
          :password   => '!',
          :home       => '/home/foo',
          :shell      => '/bin/bash',
          :require    => 'Group[testgrp]'
        )}

        it { should contain_ssh_authorized_key('foo').with(
          :ensure  => 'present',
          :key     => 'ssh-rsa AAAAB3NzaC1yc2EAAAABI',
          :user    => 'foo',
          :require => 'User[foo]'
        )}
      end

      context 'and home => /opt/foo' do
        let (:params) { {:uid => '10001', :logingroup => 'testgrp', :home => '/opt/foo' } }

        it { should contain_user('foo').with(
          :uid        => '10001',
          :name       => 'foo',
          :gid        => 'testgrp',
          :ensure     => 'present',
          :managehome => true,
          :comment    => '',
          :groups     => [],
          :password   => '!',
          :home       => '/opt/foo',
          :shell      => '/bin/bash',
          :require    => 'Group[testgrp]'
        )}
      end

      context 'and env_class => foo::bar' do
        let (:pre_condition) { 'class foo::bar( $owner, $group, $home = undef ) { }' }
        let (:params) { {:uid => '10001', :logingroup => 'testgrp', :env_class => 'foo::bar' } }

        it { should contain_class('foo::bar').with(
          :home  => '/home/foo',
          :owner => 'foo',
          :group => 'testgrp'
        )}
      end

      context 'and home => /opt/foo and env_class => foo::bar' do
        let (:pre_condition) { 'class foo::bar( $owner, $group, $home = undef ) { }' }
        let (:params) { {:uid => '10001', :logingroup => 'testgrp', :home => '/opt/foo', :env_class => 'foo::bar' } }

        it { should contain_class('foo::bar').with(
          :home => '/opt/foo',
          :owner => 'foo',
          :group => 'testgrp'
        )}
      end
    end
  end
end
