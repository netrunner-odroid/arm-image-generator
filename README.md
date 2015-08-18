## Imaging scripts for ARM boards ##

In order to use these scripts you'll need to install ruby

The simplest way to run get a image is to call :

```
  ./run.rb -c config/CONFIG_DIR
```

where CONFIG.yml is one of the various configs under the config dir

## Uboot enabled boards ##

If you have a board that uses uboot, you'll have to flash uboot to the
sdcard separately, or alternatively, flash it to the .img file produced
manually.

## Licensing ##

Everything is distributed under GPLv2.

See the COPYING file for the full license.
