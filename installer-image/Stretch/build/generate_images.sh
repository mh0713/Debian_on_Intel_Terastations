##requires gzip, rsync, wget, cpio, grub2, xorriso

distro="stretch"

mkdir debian-files output
mkdir -p payload/source

cd debian-files
if [ -d "tmp" ]; then
   rm -r "tmp/"
fi

wget -N "http://ftp.nl.debian.org/debian/dists/$distro/main/installer-amd64/current/images/netboot/mini.iso" 2 >/dev/null
cd ..

cp ../../../*.sh payload/source/
cp ../../../*.service payload/source/
cp ../../../*.patch payload/source/
cp ../../../it8721.conf payload/source/
cp ../../../module_exclude.txt payload/source/
cp -r ../../../micon_scripts payload/source/
cp ../../../micro-evtd payload/source/

xorriso -osirrox on -indev debian-files/mini.iso -extract / iso/
cp iso/initrd.gz .
if [ $? -ne 0 ]; then
        echo "failed to retrieve initrd.gz, quitting"
        exit 99
fi

kernel_ver="$(zcat initrd.gz | cpio -t | grep -m 1 lib/modules/ | gawk -F/ '{print $3}')"

gunzip initrd.gz
if [ $? -ne 0 ]; then
        echo "failed to unpack initrd.gz, quitting"
        exit 99
fi
cd payload
find . | cpio -v -H newc -o -A -F ../initrd
if [ $? -ne 0 ]; then
        echo "failed to patch initrd.gz, quitting"
        exit 99
fi
cd ..
gzip initrd
if [ $? -ne 0 ]; then
        echo "failed to pack initrd, quitting"
        exit 99
fi

cp initrd.gz iso/
cp grub.cfg iso/boot/grub/

##
rm output/*
grub-mkrescue -o "output/ts-$distro-installer.iso" iso/
if [ $? -ne 0 ]; then
        echo "failed to generate image, quitting"
        exit 99
fi

rm -r iso/
rm initrd.gz
