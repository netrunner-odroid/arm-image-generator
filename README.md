## Imaging scripts for ARM boards ##

In order to use these scripts you'll need to install ruby

The simplest way to run get a image is to call :

```
  ./run.rb -c config/CONFIG_DIR
```

where CONFIG_DIR is one of the various dirs under config/


## Partition layout ##

### When using the tar backend ###

You MUST have your parted.txt setup in a way that the first partition is a fat
partition and the second partition is where your rootfs goes.

### When using the apt backend ###

You MUST have your parted.txt setup in a way that first partition is a ext4
partition.

## Licensing ##

Everything is distributed under GPLv2.

See the COPYING file for the full license.
