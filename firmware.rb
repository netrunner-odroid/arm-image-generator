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
    begin
      unless File.exist?('cache/firmware.tar.gz') && checksum_matches?
        File.write('cache/firmware.tar.gz', open(@c.config[:firmware][:url]).read)
      end
      fail 'Checksum failed to match' unless checksum_matches?
    rescue => e
      puts "Retrying download because #{e}"
      retry
    end

    system('tar xf cache/firmware.tar.gz -C cache/firmware --strip-components=1')
    system("sudo cp -aR --no-preserve=all cache/firmware/boot/* #{target}/")
    fail 'Could not copy over firmware files!' unless $?.success?

    # Config files that are required at boottime
    system("sudo cp -aR --no-preserve=all data/firmware/* #{target}/")
  end

  def checksum_matches?
    return true if @c.config[:firmware][:md5sum].nil?

    sum = Digest::MD5.file('cache/firmware.tar.gz').hexdigest
    @c.config[:firmware][:md5sum] == sum
  end
end
