require_relative 'parted'
require_relative 'imageconfig'
require_relative 'rootfs'
require_relative 'firmware'
require_relative 'lib/mount'
require_relative 'lib/bootfile'

require 'tmpdir'
require 'tempfile'
require 'date'

# Figure out what interpreter to use
MISC_BINFMT = Dir["/proc/sys/fs/binfmt_misc/*arm"][0]
QEMU_ARM_STATIC = File.readlines(MISC_BINFMT).grep(/interpreter/)[0].split[-1]

# Class to deal with image creation
class Image
  def initialize(config)
    fail 'Could not find arm interpreter' unless QEMU_ARM_STATIC
    @c = config
  end

  def run!
    dt = DateTime.now.strftime("%Y%m%d.%H%M")
    @filename = "#{@c.config[:release]}_#{dt}.img"

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
        t[:bootfs] = boot_dir
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
    setup_bootconfig

    if @c.config[:bootloader].nil? || @c.config[:bootloader][:config].nil?
      return
    end

    @c.config[:bootloader][:uboot].keys.each do |k|
      Mount.mount(@btldrmntpt) do |boot_dir|
        Mount.mount(@rootfsmntpt) do |rootfs_dir|

          if File.exist? "#{rootfs_dir}/#{@c.config[:bootloader][:uboot][k][:file]}"
            f = "#{rootfs_dir}/#{@c.config[:bootloader][:uboot][k][:file]}"
          elsif File.exist? "#{boot_dir}/#{@c.config[:bootloader][:uboot][k][:file]}"
            f = "#{boot_dir}/#{@c.config[:bootloader][:uboot][k][:file]}"
          end

          system("sudo dd if=#{f} of=#{@loop} #{@c.config[:bootloader][:uboot][k][:dd_opts]}")
        end
      end
    end
  end

  def setup_bootconfig
    if @c.config[:bootloader].nil? || @c.config[:bootloader][:config].nil?
      return
    end

    config = BootFile.new(@c, @btldrmntpt, @rootfsmntpt)
    f = Tempfile.new('bootfile')
    f.write(config.render)
    f.close

    if @c.config[:bootloader][:config][:cmd]
      f_cmd = Tempfile.new('bootfile')
      cmd = @c.config[:bootloader][:config][:cmd]
      cmd.gsub!(/@source@/, f.path)
      cmd.gsub!(/@dest@/, f_cmd.path)
      fail "Failed to run #{cmd} on bootloader file!" unless
           system(cmd)
      f = f_cmd
    end

    Mount.mount(@btldrmntpt) do |boot_dir|
      Mount.mount(@rootfsmntpt) do |rootfs_dir|
        # Setup bootargs via a config file if any
        system("sudo mv #{f.path} #{boot_dir}/#{@c.config[:bootloader][:config][:dst]}") unless boot_dir.nil?
        system("sudo mv #{f.path} #{rootfs_dir}/#{@c.config[:bootloader][:config][:dst]}") unless rootfs_dir.nil?
      end
    end
  end
end
