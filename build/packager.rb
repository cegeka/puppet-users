gem 'fpm', '<=0.3.11'
require 'fpm'
require 'fpm/program'
require 'pp'

class Packager

  def initialize(package_type)
    self.validate_environment
    
    @basedirectory = ENV["WORKSPACE"]
    @package_version = "0.0." + ENV["BUILD_NUMBER"]
    @release = "1"
    @package_type = package_type 
    
    case package_type
    when "rpm"
      @first_delimiter, @second_delimiter, @architecture = "-", ".", "noarch"
    when "deb"
      @first_delimiter, @second_delimiter, @architecture = "_", "_", "all"
    end
  end

  def validate_environment()
    if ENV["WORKSPACE"].nil?
      fail("Environment variable WORKSPACE has not been set.")
    end
    if ENV["BUILD_NUMBER"].nil?
      fail("Environment variable BUILD_NUMBER has not been set.")
    end
  end
 
  def build(module_name)
    package_name = "cegeka-puppet-#{module_name}"
    destination_file = "#{package_name}#{@first_delimiter}#{@package_version}-#{@release}#{@second_delimiter}#{@architecture}.#{@package_type}"
    destination_folder = "#{@basedirectory}/#{module_name}/target/dist"
    url = "https://github.com/cegeka/puppet-#{module_name}"
    description = "Puppet module: #{module_name} by Cegeka\nModule #{module_name} description goes here."

    static_arguments = ["-t", @package_type, "-s", "dir", "-x", ".git", "-x", ".gitignore", "-x", "build", "-x", "Rakefile", "-a", @architecture, "-m", "Cegeka <computing@cegeka.be>", "--prefix", "/etc/puppet/modules"]
    var_arguments = ["-n", package_name, "-v", @package_version, "--iteration", @release, "--url", url, "--description", description, "-C", @basedirectory, module_name]
    arguments = static_arguments + var_arguments
    
    tmpdir = Dir.mktmpdir
    Dir.chdir tmpdir
    FileUtils.mkpath destination_folder
    packagebuild = FPM::Program.new
    ret = packagebuild.run(arguments)
    FileUtils.mv("#{tmpdir}/#{destination_file}","#{destination_folder}/#{destination_file}")
    FileUtils.remove_entry_secure(tmpdir)
    return "Created #{destination_folder}/#{destination_file}"
  end

end
