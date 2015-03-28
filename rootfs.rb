require_relative 'imageconfig'

require 'open-uri'
require 'digest'


class RootFS
  def initialize(config)
    @c = config
    @dev = %w(sys proc dev)
    system('sudo apt-get install qemu-user-static')
  end

  def install(d)
    @target = d
    Dir.mkdir('cache') unless Dir.exist?('cache')

    puts 'Downloading the rootfs'
    Dir.chdir('cache') do
      # FIXME: Assume tar.gz format for now
      unless File.exist? 'cache/rootfs.tar.gz'
        File.write('rootfs.tar.gz', open(@c.config[:rootfs][:url]).read)
      end
      checksum

      system("sudo tar xf rootfs.tar.gz -C #{@target}")
      fail 'Could not untar the rootfs!' unless $?.success?
    end

    begin
      mount
      configure
    ensure
      unmount
    end
  end

  def checksum
    return if @c.config[:rootfs][:md5sum].nil?

    sum = Digest::MD5.file('rootfs.tar.gz').hexdigest
    fail 'MD5SUM does not match' unless @c.config[:rootfs][:md5sum] == sum
  end

  def mount
    system("sudo cp /usr/bin/qemu-arm-static #{@target}/usr/bin/")
    @dev.each do |d|
      system('sudo', 'mount', '--bind', "/#{d}", "#{@target}/#{d}")
    end
  end

  def unmount
    @dev.each do |d|
      system('sudo',  'umount', "#{@target}/#{d}")
    end
    system("sudo rm #{@target}/usr/bin/qemu-arm-static")
  end

  def configure
    puts "Adding user #{@c.config[:login][:username]}"
    system("sudo chroot #{@target} useradd #{@c.config[:login][:username]}")
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
