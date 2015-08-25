## Imaging scripts for ARM boards ##

In order to use these scripts you'll need to install ruby

The simplest way to run get a image is to call :

```
  ./run.rb -c config/CONFIG_DIR
```

where CONFIG_DIR is one of the various dirs under config/


## Partition layout ##

All rootfs partitions are formatted to ext4.

### When using the tar backend ###

You **MUST** have your parted.txt setup in a way that it makes atleast 2 partitions.

Partition 1: This is where all the files from the boot/ folder of the tar
             are installed. This will be formatted to a fat partition.

Partition 2: This is where your rootfs will be installed.

### When using the apt backend ###

You **MUST** have your parted.txt setup in a way that first partition is your rootfs
partition.

Partition 1: This is where your rootfs and any packages you specify
             will be installed.

## UBoot support ##

You can specify uboot files to be flashed to the image under the :uboot:
field in config.yml

Files specified here will first be searched for in the Rootfs and then in
the first vfat partition if you have specified one in the partition table.

Each of the keys under the top level :uboot: entry will
be flashed in the order that you specify.

Each of the keys **MUST** have a :file: entry that specifies where the file
can be found.

The dd_opts entry is optional.

Example config follows:

```yml
:bootloader:
  :uboot:
    :SPL:
      :file: boot/SPL.bin
      :dd_opts: "bs=1K seek=1"
    :img:
      :file: boot/u-boot.img
      :dd_opts: "bs=1K seek=42"
```

### Boot config generation ###

If your uboot requires a special boot config that needs to land on the image,
one can be specified by using the :config: option under the :bootloader: entry.

```yml
:bootloader:
  :config:
    :src: boot.ini.rb
    :dst: boot/boot.ini
```
You can only specify one config and it **MUST** have :src: entry relative to the
config dir and a :dst: entry relative to the boot and rootfs partition.

The file will be written to both the rootfs and the boot partition if you are using
a 2 partition setup.

## Licensing ##

Everything is distributed under GPLv2.

See the COPYING file for the full license.
