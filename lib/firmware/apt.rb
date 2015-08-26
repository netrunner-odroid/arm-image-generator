class FimrwareInstaller
  def backend_install
    add_sources
    apt_update
    apt_install(@c.config[:firmware][:packages].join(' '))
  end

  def add_sources
    tmpdir = Dir.mktmpdir
    @c.config[:firmware][:sources].keys.each do |k|
      repo = "deb #{@c.config[:firmware][:sources][k]}\n"
      open("#{tmpdir}/#{k}.list", 'w') do |f|
        f.write(repo)
      end
    end
    system("sudo mv #{tmpdir}/*.list #{@rootfs}/etc/apt/sources.list.d/")
  end

  def apt_update
    system("sudo chroot #{@rootfs} apt update")
  end

  def apt_install(pkg)
    system("sudo chroot #{@rootfs} sh -c \"DEBIAN_FRONTEND=noninteractive apt -y install #{pkg}\"")
  end
end
