require 'erb'

class BootFile
  attr_accessor :rootfs_blkid
  attr_accessor :bootfs_blkid

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

  def render
    blkid_probe
    ERB.new(File.read("#{@c.config_dir}/#{@c.config[:bootloader][:config][:src]}")).result(binding)
  end
end
