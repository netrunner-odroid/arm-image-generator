require_relative 'parted'
require_relative 'imageconfig'
require_relative 'rootfs'

require 'tmpdir'

# Class to deal with image creation
class Image

  def initialize(config)
    @c = config
  end

  def run!
    @filename = "#{@c.config[:release]}.img"
    File.delete(@filename) if File.exist? @filename

    # Create file
    fail 'Cannot find qemu-img!' unless system("qemu-img create #{@filename} 8G")

    # Partition
    partition

    # Setup boot partition
    setup_bootloader

    # Install rootfs
    setup_rootfs
  end

  def partition
    # Partition the image
    p = Parted.new
    p.setup(@filename)
  end

  def setup_bootloader
    puts 'Setting up the bootloader partition'
      @btldrmntpt = `sudo losetup -o 512 --sizelimit 500M -f --show #{@filename}`.strip
    system("sudo mkfs.vfat #{@btldrmntpt}")
  end

  def setup_rootfs
    puts 'Setting up the bootloader partition'
    # FIXME: Figure out how to not set a static file size here
    @rootfsmntpt = `sudo losetup -o 500M -f --show #{@filename}`.strip
    system("sudo mkfs.ext4 #{@rootfsmntpt}")

    install_rootfs
  end

  def install_rootfs
    Dir.mktmpdir do |d|
      begin
        fail 'Mounting failed!' unless system('sudo',
                                              'mount',
                                              @rootfsmntpt,
                                              d)
        r = RootFS.new(@c)
        r.install(d)
      ensure
        system("sudo umount #{d}")
        system("sudo losetup -d #{@rootfsmntpt}")
        system("sudo losetup -d #{@btldrmntpt}")
      end
    end
  end
end
