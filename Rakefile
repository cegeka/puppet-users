require 'rubygems'
require 'rake/clean'
require 'rspec/core/rake_task'

$:.unshift(File.join(File.dirname(__FILE__), 'build'))
require 'rpm_packager'
require 'deb_packager'

CLEAN.include("")
CLOBBER.include("target")

desc "Default task prints the possible targets."
task :default do
  sh %{rake -T}
end

desc "Run puppet module RSpec tests."
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = ["--format", "doc", "--color"]
  t.fail_on_error = false
  t.pattern = 'spec/**/*_spec.rb'
end

desc "Run puppet module acceptance tests."
task :acceptance do
  puts "Running acceptance tests..."
  # cucumber ? cucumber-puppet
end

desc "Check puppet module syntax."
task :syntax do
  begin
    require 'puppet/face'
  rescue LoadError
    fail 'Cannot load puppet/face, are you sure you have Puppet 2.7?'
  end

  def validate_manifest(file)
    begin
      Puppet::Face[:parser, '0.0.1'].validate(file)
    rescue Puppet::Error => error
      puts error.message
    end
  end

  puts "Checking puppet module syntax..."
  FileList['**/*.pp'].each do |manifest|
    puts "Evaluating syntax for #{manifest}"
    validate_manifest manifest
  end
end

desc "Check puppet module code style."
task :style do
  begin
    require 'puppet-lint'
  rescue LoadError
    fail 'Cannot load puppet-lint, did you install it?'
  end

  puts "Checking puppet module code style..."
  linter = PuppetLint.new
  linter.configuration.log_format = '%{path}:%{linenumber}:%{check}:%{KIND}:%{message}'
  linter.configuration.send("disable_80chars")

  FileList['**/*.pp'].each do |puppet_file|
    puts "Evaluating code style for #{puppet_file}"
    linter.file = puppet_file
    linter.run
  end
  fail if linter.errors?
end

# TODO: Reevaluate this when/if it becomes available in Puppet Faces 
desc "Create puppet module documentation."
task :doc do
  output_dir = "target/doc"
  manifest_dir = "target/manifests"
        
  if File.directory?(output_dir)
    FileUtils.rm_r output_dir
  end
  if File.directory?(manifest_dir)
    FileUtils.rm_r manifest_dir
  end
  FileUtils.mkdir_p manifest_dir
  
  puts "Generating puppet module documentation..."
  FileUtils.mkdir_p("target/manifests")
  sh %{puppet doc --mode rdoc --manifestdir target/manifests/ --modulepath ../ --outputdir target/doc}

  work_dir = File.dirname(__FILE__)
  parent_dir = File.dirname(work_dir)

  if File.exists? "#{work_dir}/target/doc/files/#{work_dir}"
    FileUtils.mv "#{work_dir}/target/doc/files/#{work_dir}", "#{work_dir}/target/doc/files"
  end

  FileList['target/doc/**/*.html'].egrep(%r(#{parent_dir})) do |fn,line,match|
    text = File.read(fn)
    replace = text.gsub(%r(#{parent_dir}), "")
    File.open(fn, "w") { |file| file.puts replace }
  end

  FileList['target/doc/files/**/*_pp.html'].egrep(/rdoc-style\.css/) do |fn,line,match|
    depth_in_doc = fn.split(/\//).length - 3
    original_string = /[\.\/]*rdoc-style.css/
    replacement_string = '../' * depth_in_doc + 'rdoc-style.css'
    text = File.read(fn)
    replace = text.gsub(original_string, replacement_string)
    File.open(fn, "w") { |file| file.puts replace }
  end
end

desc "Create RPM package from puppet module."
task :rpm do
  puts "Creating RPM package from puppet module..."
  module_name = ENV["JOB_NAME"].split('-')[1]

  rpm_packager = RpmPackager.new
  output = rpm_packager.build(module_name)
  puts output
end
  
desc "Create DEB package from puppet module."
task :deb do
  puts "Creating DEB package from puppet module..."
  module_name = ENV["JOB_NAME"].split('-')[1]
  
  deb_packager = DebPackager.new
  output = deb_packager.build(module_name)
  puts output
end

desc "Create a puppet module, compatible with Puppet Forge."
task :build do
  begin
    require 'puppet/face'
  rescue LoadError
    fail 'Cannot load puppet/face, are you sure you have Puppet 2.7?'
  end

  puts "Creating puppet module for Puppet Forge..."
  # puppet module build / upload to forge
  #Puppet::Face[:module, '1.0.0'].build()
end

desc "Create a version tag for the current commit."
task :tag, [:version] do |t,args|
  puts "Tagging version #{args.version}"
  # git tag
  # deal with ChangeLog
end

desc "Create a puppet module release for the provided version."
task :release, [:version] => [:tag] do |t,args|
  puts "Releasing version #{args.version}"
  # checkout tag / build rpm/deb/forge package
end

namespace "jenkins" do
  begin
    require 'ci/reporter/rake/rspec'
    require 'ci/reporter/rake/cucumber'
  rescue LoadError
    fail 'Cannot load ci_reporter, did you install it?'
  end
  
  SPEC_REPORTS_PATH = "target/reports/spec/"
  ACCEPTANCE_REPORTS_PATH = "target/reports/acceptance/"

  desc "Run Jenkins compatible Rspec tests."
  task :spec_tests => ["ci:setup:rspec"] do
    ENV["CI_REPORTS"] = SPEC_REPORTS_PATH
    FileUtils.mkdir_p(SPEC_REPORTS_PATH)
    
    Rake::Task[:spec].invoke
  end

  desc "Run Jenkins compatible acceptance tests."
  task :acceptance_tests => ["ci:setup:cucumber"] do
    ENV["CI_REPORTS"] = ACCEPTANCE_REPORTS_PATH
    FileUtils.mkdir_p(ACCEPTANCE_REPORTS_PATH)
    
    Rake::Task[:acceptance].invoke
  end

  desc "Archive job configuration in YAML format."
  task :archive_job_configuration do
    dist_dir = "target/dist"

    module_name = ENV["JOB_NAME"]
    git_commit = ENV["GIT_COMMIT"]
    
    if !git_commit.nil? and !git_commit.empty?
      puts "Saving #{module_name}.yaml file" 
      FileUtils.mkdir_p(dist_dir)
      open("target/dist/#{module_name}.yaml", "w") { |file|
	file.puts "module_name: #{module_name}"
	file.puts "git_commit: #{git_commit}"
      }
    end
  end
end
