require_relative 'imageconfig'

require 'open-uri'
require 'fileutils'
require 'digest'

# Class to handle firmware installation
class Firmware
  def initialize(config)
    @c = config
  end

  def install(target)
    @target = target

    FileUtils.rm_rf('cache/firmware')
    FileUtils.mkdir_p('cache/firmware')

    puts 'Downloading firmware.tar.gz'

    # FIXME: Assume tar.gz format for now
    Dir.chdir('cache') do
      unless File.exist? 'firmware.tar.gz'
        File.write('firmware.tar.gz', open(@c.config[:firmware][:url]).read)
      end
      system('tar xf firmware.tar.gz -C firmware --strip-components=1')
      system("sudo cp -aR firmware/boot/* #{target}/")
    end
  end

  def checksum
    return if @c.config[:firmware][:md5sum].nil?

    sum = Digest::MD5.file('cache/firmware.tar.gz').hexdigest
    fail 'MD5SUM does not match' unless @c.config[:firmware][:md5sum] == sum
  end
end
