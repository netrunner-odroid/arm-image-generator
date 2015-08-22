require_relative 'imageconfig'
require_relative 'lib/firmware/installer'

require 'open-uri'
require 'fileutils'
require 'digest'

# Class to handle firmware installation
class Firmware
  def initialize(config)
    @c = config
  end

  def install(target)
    return unless @c.config[:firmware]

    f = FimrwareInstaller.new(@c)
    f.install(target)
  end
end
