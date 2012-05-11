require File.expand_path('../../../env', __FILE__)

class ModulefileReader

	def initialize()
		filename = File.join(MODULE_ROOT_DIR, 'Modulefile')
		@module_file = File.read(filename)
	end

	def version
    @module_file.each_line do |line|
      if line.match(/version/)
        return line.split(' ')[1].gsub("'", "")
      end
		end
	end

end
