require 'rake/clean'

require File.expand_path('../../env', __FILE__)

CLEAN.include("")
CLOBBER.include("#{RESULTS}")
