require 'tmpdir'

class Mount
  def self.mount(path)
    mntdir = Dir.mktmpdir
    fail 'Mounting partition failed!' unless system('sudo',
                                                         'mount',
                                                         path,
                                                         mntdir)
    yield mntdir
  ensure
    system('sudo',
           'umount',
           mntdir)
  end
end
