class FimrwareInstaller
  def backend_install
    divert_files
    add_sources
    apt_update
    apt_install(@c.config[:firmware][:packages].join(' '))
    undivert_files
  end

  def divert_files
    system("sudo chroot #{@rootfs} dpkg-divert --rename --quiet --add /sbin/start-stop-daemon")
    system("sudo chroot #{@rootfs} ln -s /bin/true /sbin/start-stop-daemon")
  end

  def undivert_files
    system("sudo rm #{@rootfs}/sbin/start-stop-daemon")
    system("sudo chroot #{@rootfs} dpkg-divert --rename --quiet --remove /sbin/start-stop-daemon")
  end

  def add_sources
    tmpdir = Dir.mktmpdir
    @c.config[:firmware][:sources].keys.each do |k|
      repo = "deb #{@c.config[:firmware][:sources][k]}\n"
      open("#{tmpdir}/#{k}.list", 'w+') do |f|
        f.write(repo)
      end
    end
    system("sudo mv #{tmpdir}/*.list #{@rootfs}/etc/apt/sources.list.d/")
  end

  def apt_update
    system("sudo chroot #{@rootfs} apt update")
  end

  def apt_install(pkg)
    fail 'Failed to install' unless
    system("sudo chroot #{@rootfs} sh -c \"DEBIAN_FRONTEND=noninteractive apt --force-yes -y install #{pkg}\"")
  end
end
