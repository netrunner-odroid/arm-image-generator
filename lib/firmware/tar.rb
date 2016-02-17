require 'open-uri'
require 'fileutils'
require 'digest'

class FimrwareInstaller
  FIRMWARE_DIR = 'cache/firmware'

  def backend_install
    @libdir = "#{@rootfs}/lib"

    FileUtils.rm_rf(FIRMWARE_DIR)
    FileUtils.mkdir_p(FIRMWARE_DIR)

    puts 'Downloading firmware.tar.gz'
    retry_times = 0

    @firmwareFile = File.basename(URI.parse(@c.config[:firmware][:url]).path)

    # FIXME: Assume tar.gz format for now
    begin
      unless File.exist?("cache/#{@firmwareFile}") && checksum_matches?
        system("wget -P cache/ #{@c.config[:firmware][:url]}")
      end
      raise 'Checksum failed to match' unless checksum_matches?
    rescue => e
      puts "Retrying download because #{e}"
      retry_times += 1
      retry if retry_times < 3
    end

    # In case a firmware tar is a unicorn, one needs to adjust this accordingly
    tar_args = ENV['FIRMWARE_TAR_ARGS']
    tar_args ||= '--strip-components 1'
    system("tar xf cache/#{@firmwareFile} -C #{FIRMWARE_DIR} -p -s #{tar_args}")
    Dir["#{FIRMWARE_DIR}/**/boot"].each do |dir|
      unless system("sudo cp -aR --no-preserve=all #{dir}/* #{@bootfs}/")
        raise 'Could not copy over firmware files!'
      end
    end

    install_rest
  end

  def install_rest
    Dir[FIRMWARE_DIR].each do |dir|
      next if dir.include? 'boot'
      rsync(dir, @rootfs)
    end
  end

  def rsync(src, target)
    return unless Dir.exist? src
    system("sudo rsync -r -t -p -o -g -x -l -H -D --numeric-ids -s #{src}/ #{target}/")
  end

  def checksum_matches?
    return true if @c.config[:firmware][:md5sum].nil?

    sum = Digest::MD5.file("cache/#{@firmwareFile}").hexdigest
    @c.config[:firmware][:md5sum] == sum
  end

  private :backend_install
end
