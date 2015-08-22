## Imaging scripts for ARM boards ##

In order to use these scripts you'll need to install ruby

The simplest way to run get a image is to call :

```
  ./run.rb -c config/CONFIG_DIR
```

where CONFIG_DIR is one of the various dirs under config/


## Partition layout ##

### When using the tar backend ###

You **MUST** have your parted.txt setup in a way that the first partition is a fat
partition and the second partition is where your rootfs goes.

### When using the apt backend ###

You **MUST** have your parted.txt setup in a way that first partition is a ext4
partition.

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
:uboot:
  :SPL:
    :file: boot/SPL.bin
    :dd_opts: "bs=1K seek=1"
  :img:
    :file: boot/u-boot.img
    :dd_opts: "bs=1K seek=42"
```

## Licensing ##

Everything is distributed under GPLv2.

See the COPYING file for the full license.
