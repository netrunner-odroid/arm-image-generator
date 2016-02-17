require_relative 'mount'

require 'erb'

class BootFile
  attr_accessor :rootfs_blkid
  attr_accessor :bootfs_blkid
  attr_accessor :uImages, :uImage
  attr_accessor :uInitrds, :uInitrd
  attr_accessor :c

  def initialize(config, btldrmntpt, rootfsmntpt)
    @c = config
    @btldrmntpt = btldrmntpt
    @rootfsmntpt = rootfsmntpt
  end

  def blkid_probe
    @rootfs_blkid = `sudo blkid -sUUID -ovalue #{@rootfsmntpt}`.strip
    return if @btldrmntpt.nil?

    @bootfs_blkid = `sudo blkid -sUUID -ovalue #{@btldrmntpt}`.strip
  end

  def uImage_probe
    @uImages = []
    Mount.mount(@btldrmntpt) do |boot_dir|
      unless boot_dir.nil?
        Dir.chdir(boot_dir) do
          @uImages += Dir["boot/uImage*"]
          @uImages += Dir["uImage*"]
        end
      end
    end

    Mount.mount(@rootfsmntpt) do |rootfs_dir|
      Dir.chdir(rootfs_dir) do
        @uImages += Dir["boot/uImage*"]
      end
    end

    @uImages.sort!
    @uImage = @uImages[-1]
  end

  def uInitrd_probe
    @uInitrds = []
    Mount.mount(@btldrmntpt) do |boot_dir|
      unless boot_dir.nil?
        Dir.chdir(boot_dir) do
          @uInitrds += Dir["boot/uInitrd*"]
          @uInitrds += Dir["uInitrd*"]
        end
      end
    end

    Mount.mount(@rootfsmntpt) do |rootfs_dir|
      Dir.chdir(rootfs_dir) do
        @uInitrds += Dir["boot/uInitrd*"]
      end
    end

    @uInitrds.sort!
    @uInitrd = @uInitrds[-1]
  end

  def render
    blkid_probe
    uImage_probe
    uInitrd_probe
    file_path = "#{@c.config_dir}/#{@c.config[:bootloader][:config][:src]}"
    ERB.new(File.read(file_path)).result(binding)
  end
end
