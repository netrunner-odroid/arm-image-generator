require_relative 'parted'
require_relative 'imageconfig'
require_relative 'rootfs'
require_relative 'firmware'
require_relative 'lib/mount'

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
    begin
      # Partition
      partition
      # loop device setup
      loop_setup
      # Install rootfs
      setup_rootfs
      # Setup firmware and other stuff
      setup_firmware
    ensure
      # loop device loop_teardown
      loop_teardown
    end
  end

  def loop_setup
    @loop = `sudo losetup --show -f -P #{@filename}`.strip
    `sudo partprobe #{@loop}`

    # FIXME: Hard coded for now
    @btldrmntpt  = "#{@loop}p1"
    @rootfsmntpt = "#{@loop}p2"

    fail 'Could not setup loop mounts.\
          Make sure you have util-linux v2.21 or higher' unless $?.success?
  end

  def loop_teardown
    `sudo losetup -d #{@loop}`
    fail 'Could not tear down loop mounts!' unless $?.success?
  end

  def partition
    # Partition the image
    p = Parted.new(@c)
    p.setup(@filename)
  end

  def setup_firmware
    puts 'Setting up the bootloader partition'
    system("sudo mkfs.vfat #{@btldrmntpt}")
    system("sudo fsck.vfat #{@btldrmntpt}")
    install_firmware
  end

  def install_firmware
    t = {}
    Mount.mount(@btldrmntpt) do |boot_dir|
      Mount.mount(@rootfsmntpt) do |rootfs_dir|
        f = Firmware.new(@c)
        t[:boot] = boot_dir
        t[:rootfs] = rootfs_dir
        f.install(t)
      end
    end
  end

  def setup_rootfs
    puts 'Setting up the rootfs partition'
    system("sudo mkfs.ext4 #{@rootfsmntpt}")
    system("sudo fsck.ext4 #{@rootfsmntpt}")
    install_rootfs
  end

  def install_rootfs
    Mount.mount(@rootfsmntpt) do |d|
      r = RootFS.new(@c)
      r.install(d)
    end
  end
end
