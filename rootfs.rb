require_relative 'imageconfig'

require 'open-uri'
require 'digest'
require 'rubygems/package'
require 'zlib'

class RootFS
  def initialize(config)
    @c = config
    @dev = %w(sys proc dev)
    system('sudo apt-get -qq -y install qemu-user-static')
  end

  def install(target)
    return unless @c.config[:rootfs]

    @target = target
    retry_times = 0
    Dir.mkdir('cache') unless Dir.exist?('cache')

    puts 'Downloading the rootfs'
    # FIXME: Assume tar.gz format for now
    begin
      unless File.exist?('cache/rootfs.tar.gz') && checksum_matches?
        File.write('cache/rootfs.tar.gz', open(@c.config[:rootfs][:url]).read)
      end
      fail 'Checksum failed to match' unless checksum_matches?
    rescue => e
      puts "Retrying download because #{e}"
      retry_times += 1
      retry if retry_times < 3
    end

    # FIXME: This should be really be a bit more properly tuned
    tar = Gem::Package::TarReader.new(Zlib::GzipReader.open('cache/rootfs.tar.gz'))
    tar.rewind
    useradd = tar.select { |e| e if e.full_name.include? 'useradd' }[0]
    tar.close
    components = useradd.full_name.split('usr')[0].split('/').count
    ec = system("sudo tar xf cache/rootfs.tar.gz -C #{@target} --strip-components #{components}")
    fail 'Could not untar the rootfs!' unless ec

    begin
      mount
      configure
    ensure
      unmount
    end
  end

  def checksum_matches?
    return true if @c.config[:rootfs][:md5sum].nil?
    sum = Digest::MD5.file('cache/rootfs.tar.gz').hexdigest
    @c.config[:rootfs][:md5sum] == sum
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
    configure_login if @c.config.keys.include? :login
  end

  def configure_login
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
