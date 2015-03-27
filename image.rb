require_relative 'parted'
require_relative 'imageconfig'
require_relative 'rootfs'

require 'tmpdir'

# Class to deal with image creation
class Image

  def initialize(config)
    @c = config
  end

  def run!(file = 'debian.img', release = 'sid')
    @file = file
    @release = release
    File.delete(file) if File.exist? file

    # Create file
    fail 'Cannot find qemu-img!' unless system("qemu-img create #{file} 8G")

    # Partition
    partition

    # Install rootfs
    install_rootfs
  end

  def partition
    # Partition the image
    p = Parted.new
    p.setup(@file)
  end

  def install_rootfs
    # FIXME: Figure out how to not set a static file size here
    mntpt = `sudo losetup -o 500M -f --show #{@file}`.strip
    system("sudo mkfs.ext4 #{mntpt}")

    Dir.mktmpdir do |d|
      begin
        fail 'Mounting failed!' unless system('/usr/bin/sudo',
                                              '/bin/mount',
                                              mntpt,
                                              d)
        r = RootFS.new(@c)
        r.install(d)
      ensure
        system("sudo umount #{d}")
        system("sudo losetup -d #{mntpt}")
        puts "All done!"
      end
    end
  end
end
