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
      # Setup bootloader
      setup_btldr
    ensure
      # loop device loop_teardown
      loop_teardown
    end
  end

  def loop_setup
    @loop = `sudo losetup --show -f -P #{@filename}`.strip
    fail 'Could not setup loop mounts.\
          Make sure you have util-linux v2.21 or higher' unless $?.success?

    count = Dir["#{@loop}p*"].count

    if @c.config[:firmware][:backend] == 'tar' && count != 2
      fail 'Incompatible partition/backend settings detected!'
    end

    # FIXME: Figure out how to make this better
    if @c.config[:firmware][:backend] == 'tar'
      @btldrmntpt  = "#{@loop}p1"
      @rootfsmntpt = "#{@loop}p2"
    else
      @rootfsmntpt = "#{@loop}p1"
    end
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

    # We only setup a separate the vfat partition if we have the tar backend
    if @c.config[:firmware][:backend] == 'tar'
      system("sudo mkfs.vfat #{@btldrmntpt}")
      system("sudo fsck.vfat #{@btldrmntpt}")
    end

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

  def setup_btldr
    @c.config[:uboot].keys.each do |k|
      Mount.mount(@btldrmntpt) do |boot_dir|
        Mount.mount(@rootfsmntpt) do |rootfs_dir|

          if File.exist? "#{rootfs_dir}/#{@c.config[:uboot][k][:file]}"
            f = "#{rootfs_dir}/#{@c.config[:uboot][k][:file]}"
          elsif File.exist? "#{boot_dir}/#{@c.config[:uboot][k][:file]}"
            f = "#{boot_dir}/#{@c.config[:uboot][k][:file]}"
          end

          system("sudo dd if=#{f} of=#{@loop} #{@c.config[:uboot][k][:dd_opts]}")
        end
      end
    end
  end
end
