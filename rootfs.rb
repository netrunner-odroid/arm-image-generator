require_relative 'imageconfig'

require 'open-uri'
require 'digest'
require 'rubygems/package'
require 'zlib'
require 'uri'
require 'fileutils'

class RootFS
  def initialize(config)
    @c = config
    @dev = %w(sys proc dev)
  end

  def install(target)
    return unless @c.config[:rootfs]

    @target = target
    retry_times = 0
    Dir.mkdir('cache') unless Dir.exist?('cache')

    uri = URI.parse(@c.config[:rootfs][:url])
    @rootfsFile = File.basename(uri.path)

    puts 'Downloading the rootfs'
    if uri.scheme == 'file'
      FileUtils.cp(@rootfsFile, 'cache/')
    else
      download_rootfs
    end

    # In case a rootfs tar is a unicorn, one needs to adjust this accordingly
    tar_args = ENV['ROOTFS_TAR_ARGS']
    tar_args ||= '--strip-components 1'
    ec = system("sudo tar xf cache/#{@rootfsFile} -p -s -C #{@target} #{tar_args}")
    fail 'Could not untar the rootfs!' unless ec

    begin
      mount
      configure
    ensure
      unmount
    end
  end

  def download_rootfs
    # FIXME: Assume tar.gz format for now
    begin
      unless File.exist?("cache/#{@rootfsFile}") && checksum_matches?
        system("axel -n 10 -a -o cache/ #{@c.config[:rootfs][:url]}")
      end
      fail 'Checksum failed to match' unless checksum_matches?
    rescue => e
      puts "Retrying download because #{e}"
      retry_times += 1
      retry if retry_times < 3
    end
  end

  def checksum_matches?
    return true if @c.config[:rootfs][:md5sum].nil?
    sum = Digest::MD5.file("cache/#{@rootfsFile}").hexdigest
    @c.config[:rootfs][:md5sum] == sum
  end

  def mount
    system("sudo cp #{QEMU_ARM_STATIC} #{@target}/usr/bin/")
    @dev.each do |d|
      system('sudo', 'mount', '--bind', "/#{d}", "#{@target}/#{d}")
    end
  end

  def unmount
    @dev.each do |d|
      system('sudo',  'umount', "#{@target}/#{d}")
    end
    system("sudo rm #{@target}/#{QEMU_ARM_STATIC}")
  end

  def configure
    configure_login if @c.config.keys.include? :login
  end

  def configure_login
    return if @c.config[:login][:username].nil?

    puts "Adding user #{@c.config[:login][:username]}"
    system("sudo chroot #{@target} useradd -m #{@c.config[:login][:username]}")
    fail 'Could not add the user!' unless $?.success?

    puts 'Setting the password'
    # Mental password command
    pswdcmd = "sh -c \"echo \"#{@c.config[:login][:password]}:#{@c.config[:login][:username]}\" | chpasswd\""
    system("sudo chroot #{@target} #{pswdcmd}")
    fail 'Could not add the user!' unless $?.success?

    @c.config[:login][:groups].each do |g|
      puts "Adding user to #{g} group"
      system("sudo chroot #{@target} usermod -a -G #{g} #{@c.config[:login][:username]}")
      fail 'Could not add the user to the #{g} group!' unless $?.success?
    end
  end
end
