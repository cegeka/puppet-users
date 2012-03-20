require 'spec_helper'

describe 'users::localgroup' do
  context 'with an non-alphanumeric title' do
    let (:title) { 'foo bar' }
    let (:params) { {:gid => '10001'} }

    it { 
      expect { subject }.to raise_error(
        Puppet::Error, /namevar must be alphanumeric/
    )}
  end

  context 'with a non-alphabetic first character in the title' do
    let (:title) { '1foo' }
    let (:params) { {:gid => '10001'} }

    it { 
      expect { subject }.to raise_error(
        Puppet::Error, /namevar must be alphanumeric/
    )}
  end

  context 'with an alphanumeric title' do
    let (:title) { 'testgrp1' }

    context 'and parameter gid unset' do
      it {
        expect { subject }.to raise_error(
          Puppet::Error, /Must pass gid/
      )}
    end

    context 'and gid => foo' do
      let (:params) { {:gid => 'foo'} }

      it {
        expect { subject }.to raise_error(
          Puppet::Error, /parameter gid must be numeric/
      )}
    end

    context 'and gid => 10001' do
      context 'and ensure => stopped' do
        let (:params) { {:gid => '10001', :ensure => 'stopped'} }

        it {
          expect { subject }.to raise_error(
            Puppet::Error, /parameter ensure must be present or absent/
        )}
      end

      context 'and ensure => absent' do
        let (:params) { {:gid => '10001', :ensure => 'absent'} }

        it { should contain_group('testgrp1').with(
          :ensure => 'absent'
        )} 
      end

      context 'and gid => 10001' do
        let (:params) { {:gid => '10001'} }

        it { should contain_group('testgrp1').with(
          :ensure => 'present',
          :name   => 'testgrp1',
          :gid    => '10001'
        )}
      end
    end
  end
end
