require_relative 'parted'
require_relative 'imageconfig'
require_relative 'rootfs'
require_relative 'firmware'

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
    fail 'Cannot find qemu-img!' unless system('qemu-img',
                                               'create',
                                               "#{@filename}",
                                               "#{@c.config[:size]}")
    # Partition
    partition

    # loop device setup
    loop_setup

    # Setup boot partition
    setup_firmware

    # Install rootfs
    setup_rootfs

    # loop device loop_teardown
    loop_teardown
  end

  def loop_setup
    @loop = `sudo losetup --show -f -P #{@filename}`.strip
    fail 'Could not setup loop mounts.\
          Make sure you have util-linux v2.21 or higher' if @loop.nil?
  end

  def loop_teardown
    `sudo losetup -d #{@loop}`
    fail 'Could not tear down loop mounts!' unless $?.success?
  end

  def partition
    # Partition the image
    p = Parted.new
    p.setup(@filename)
  end

  def setup_firmware
    puts 'Setting up the bootloader partition'
    # FIXME: Hard coded for now
    @btldrmntpt = "#{@loop}p1"
    system("sudo mkfs.vfat #{@btldrmntpt}")
    system("sudo fsck.vfat #{@btldrmntpt}")
    install_firmware
  end

  def install_firmware
    Dir.mktmpdir do |d|
      begin
        fail 'Mounting failed!' unless system('sudo',
                                              'mount',
                                              @btldrmntpt,
                                              d)
        r = Firmware.new(@c)
        r.install(d)
      ensure
        system("sudo umount #{d}")
      end
    end
  end

  def setup_rootfs
    puts 'Setting up the bootloader partition'
    # FIXME: Hard coded for now
    @rootfsmntpt = "#{@loop}p2"
    system("sudo mkfs.ext4 #{@rootfsmntpt}")
    system("sudo fsck.ext4 #{@rootfsmntpt}")
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
      end
    end
  end
end
