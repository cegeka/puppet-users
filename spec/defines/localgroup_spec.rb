require 'spec_helper'

describe 'users::localgroup' do
  context 'with an non-alphanumeric title' do
    let (:title) { 'foo bar' }

    it { 
      expect { should contain_group('foo bar') 
      }.to raise_error(Puppet::Error, /namevar must be alphanumeric/) }
  end

  context 'with an alphanumeric title' do
    let (:title) { 'testgrp1' }

    context 'and gid => foo' do
      let (:params) { {:gid => 'foo'} }

      it {
        expect { should contain_group('testgrp1') 
        }.to raise_error(Puppet::Error, /parameter gid must be numeric/) }
    end

    context 'and gid => 10001' do
      context 'and ensure => stopped' do
        let (:params) { {:gid => '10001', :ensure => 'stopped'} }

        it {
          expect { should contain_group('testgrp1') 
          }.to raise_error(Puppet::Error, /parameter ensure must be present or absent/) }
      end

      context 'and ensure => absent' do
        let (:params) { {:gid => '10001', :ensure => 'absent'} }

        it { should contain_group('testgrp1').with_ensure('absent') } 
      end

      context 'and gid => 10001' do
        let (:params) { {:gid => '10001'} }

        it { should contain_group('testgrp1').with_name('testgrp1').with_gid('10001') }
      end
    end
  end
end
