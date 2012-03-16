#!/usr/bin/env rspec

require 'spec_helper'

describe 'users' do
  it { should contain_class 'users' }
end
