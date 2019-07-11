![alt text](https://static.miraheze.org/buffalonaswiki/thumb/5/5f/Tsx86_lcd2.jpg/800px-Tsx86_lcd1.jpg)

# Debian_on_Intel_Terastations
Tools for running Debian effectively on Intel-based Buffalo Terastations (TS/WS-WVHL/QVHL/6VHL/8VHL/RVHL, TS4000,TS5000)

Buffalo's Intel-based Terastations are very similar to a fairly typical PC with their built in USB and VGA ports. This allows you to Install any operating system you want on them though without some of the features provided by Buffalo's firmware. The goal of this project is to provide tools which can be used to handle some of the features not automatically dealt with by a normal Debian install.

The specific issues I'm currently addressing are:

### Hotswap bays (hotswap_enable.sh, hotswap.service, build-modules.sh and drive_detect_example.sh)
When these devices startup they scan each drive bay to determine which have drives and enable power for just those bays. Normally the ability to add drives to an empty bay is handled by Buffalo's software. To replicate this behaviour under Debian it is necessary to add a kernel module which allows us to access the GPIO pins used to detect drives and enable power to the bays.

* build-modules.sh - A script which automatically builds and installs the missing GPIO driver needed to enable/disable drive bays and detect drive insert/removal. This is from my other project (https://github.com/1000001101000/Debian_Module_Builder)
* hotswap_enable.sh - A script which calls build-modules.sh to ensure the GPIO driver is loaded then makes sure all the device's drive bays are enabled. This also serves as an example of how to enable/disable bays from userspace.
* hotswap.service - A systemd service which runs hotswap_enable.sh at startup.
* drive_detect_example.sh - A script demonstrating how to detect drives being inserted or removed using the GPIO interface. This could be used to detect when a drive is inserted and then power up the corresponding bay rather than the simple enable script I'm using. 

To install these manually:
* Copy hotswap_enable.sh and build-modules.sh to /usr/local/bin/
* Copy hotswap.service to /etc/systemd/system/
* Run systemctl enable hotswap.service

### Boot loader (update_boot.sh)
Typically you'll want to have your boot/root partitions replicated across each disk (via RAID1) so that the device can still boot in the event that the first drive fails. Although Debian will automatically update your Grub configuration for you when a configuration change is needed it will only install the updated Grub to boot sector of one drive. I've put together a script that automatically determines which drive(s) contain /boot and installs Grub to the boot sector of each. I set it up to run whenever update-initramfs runs which covers most scenarios where grub needs to be updated (ie kernel updates and filesystem/raid changes). You should run it manually any other time you make a change to the grub configuration.

To install manually:
* Copy update_boot.sh to /usr/local/bin/
* Create the /etc/initramfs/post-update.d/ directory
* Create a symlink of update_boot.sh in /etc/initramfs/post-update.d/

## Fans
The fan speeds can be monitored/controlled via the IT8721f chip. Fortunately, the necessary driver is included with the kernel. The fan speed can be adjusted automatically using fancontrol and monitored using lmsensors.

To set it up manually:
* install lm-sensors and fancontrol "apt-get install lm-sensors fancontrol"
* load the it87 kernel module "modprobe it87"
* add the module to /etc/modules "echo it87 >> /etc/modules"
* run "pwmconfig" and follow the prompts to set up a fancontrol config.
* run "sensors" to monitor you temperature and fan speeds
  note: the voltage sensors will return strange data which is probably best ignored. 

## Buttons (button_example.sh, it87-gpio.patch, build-modules.sh)
These devices use some spare pins from the IT8721f chip to control the "display" and "function" buttons on the front. The GPIO function of the IT8721 isn't normally supported by the gpio-it87 module so it is necessary to apply a patch to enable it.  I've included the necessary patch and added logic to build-modules.sh to automatically apply it. I've also included a script that demonstrates how to read the GPIO values to determine when one of the buttons is pressed.

To use it:
* Copy button_example.sh to /usr/local/bin/ (the installer image will do that automatically if you use it)
* Run build-module.sh (this happens at startup if you use the installer or set it up in the hotswap section)
* Run button_example.sh, the script will output the GPIO values each time you press/release one of the buttons.

## LCD Screen/LEDs/Buzzer
The LCD screen, LEDs and Buzzer are all controlled by an internal micorcontroller connected via an internal serial connection. Due to the complexity of working with chip and because it is used by Intel and non-Intel Terastations I've created a seperate project for those scripts.

For the python library used to communicate with this chip and some example scripts see:

https://github.com/1000001101000/Python_buffalo_libmicon/blob/master/README.md

For the installer I've added lcd_init.service which initializes the LCD display and power LED at startup.


### Headless installer (/installer-image/)
Although you can hook up a USB keyboard and VGA monitor and install Debian using one of the installer images provided by Debian, I've provided and image which allows you to run the install remotely over SSH and automatically installs the tools I listed above. I've included the scripts I use to build the image in the "build" directory.

To use it:
* Download the .iso file from the installer-image directory
* Write the image to a USB drive (dd if=ts-stretch-installer.iso of=/dev/sdx bs=1M)
* Insert the drive into one of the devices USB 2.0 ports
* Flip the switch on the back of the device to "USB" and reboot it.
* After a few minutes; log into the device via SSH, the username is installer and the password is install
* Run through the Debian install like normal.
* When the install finishes flip the switch on the back of the device to "HDD" and reboot it.

