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
    p = Parted.new
    p.setup(@filename)
  end

  def setup_firmware
    puts 'Setting up the bootloader partition'
    system("sudo mkfs.vfat #{@btldrmntpt}")
    system("sudo fsck.vfat #{@btldrmntpt}")
    install_firmware
  end

  def install_firmware
    boot_dir = Dir.mktmpdir
    rootfs_dir = Dir.mktmpdir
    t = {}
    begin
      fail 'Mounting boot partition failed!' unless system('sudo',
                                                           'mount',
                                                           @btldrmntpt,
                                                           boot_dir)
      fail 'Mounting rootfs partition failed' unless system('sudo',
                                                            'mount',
                                                            @rootfsmntpt,
                                                            rootfs_dir)
      r = Firmware.new(@c)
      t[:boot] = boot_dir
      t[:modules] = "#{rootfs_dir}/lib/modules/"
      r.install(t)
    ensure
      system('sudo', 'umount', boot_dir)
      system('sudo', 'umount', rootfs_dir)
    end
  end

  def setup_rootfs
    puts 'Setting up the bootloader partition'
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
