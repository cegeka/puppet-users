require 'packager'

class RpmPackager < Packager

  PACKAGETYPE = "rpm"

  def initialize()
    super(PACKAGETYPE)
  end

end
