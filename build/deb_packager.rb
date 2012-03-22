require 'packager'

class DebPackager < Packager

  PACKAGETYPE = "deb"

  def initialize()
    super(PACKAGETYPE)
  end

end
