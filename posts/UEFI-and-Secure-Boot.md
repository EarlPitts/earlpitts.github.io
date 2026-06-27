---
title: "UEFI and Secure Boot"
date: 2021-06-21T09:56:41+01:00
toc: false
images:
tags:
  - linux 
  - uefi
  - secure boot
---

Not too long ago, I had to figure out how to boot into linux with secure boot enabled, without modifying the key database.
As it turns out, this is not a trivial task, so I spent like half a day on a weekend, researching the topic, but I finally figured out a way to do it.
I wrote this post in the hope that it could help others in similar situations.
Note that I mostly discuss the solution for my setup, so it may not be applicable for yours, but I tried to provide all the background info that I think is relevant, so you can hopefully find a solution for your exact problem.

For starters, let's look at the firmware.

# Firmware Types

There are basically two types of firmware today, that's used almost everywhere: BIOS and UEFI.
These are proprietary software, implemented by the hardware vendor, although there exist some FOSS firmware like libreboot and coreboot.
Newer hardware usually ships with UEFI, which is the newer one of the two.

The main difference between them is the way they boot into the OS: BIOS uses the MBR (Master Boot Record) to initiate the boot process, while UEFI is able to read the filesystem, so it can search for it's "EFI apps" anywhere on the disk.
These two methods are fundamentally different, so it's not really possible to use them interchangeably, although UEFI can boot in legacy mode, which can be thought of as "BIOS mode", because it basically emulates what BIOS does.
After you installed the OS, there is no easy way to change between these modes.
If you boot from the install medium in BIOS mode, it will install the OS in BIOS native mode.
If you boot it in UEFI mode, it will install it in UEFI native mode.

Another thing that has to be kept in mind while choosing between UEFI and BIOS is that UEFI, if used natively, not in legacy mode, requires the GPT partitioning scheme.

# UEFI

UEFI stands for Unified Extensible Firmware Interface.
It's main goal is to standardize the booting process, and provide basic functionalities that were missing from BIOS.
It's important to note that UEFI is just a specification, that would, in an ideal world, be fully implemented by the hardware vendors (which, unfortunately, is not always the case).

Because UEFI can read the *partition table* and even the *file system*, it's much more flexible than BIOS, which requires from the image that it boots to be in the master boot record of the disk.
To see how limiting this is: the master boot record is the first 512 bytes of the disk.
And it also contains the partition table, so about 440 bytes remain for the bootstrap code, which starts the boot process.
Of course nowadays half a kilobyte is not enough for anything, so what happens is that bootloaders use some kind of stub, that they place in the MBR, whose only job is to call the bootloader.

In contrast, with UEFI you can put as many bootloaders on your disk as you want, taking up as much space as you want.
The only requirements is that it has to be executable by UEFI, and the partition in which it resides, has to be an *EFI partition* (which is just a specific version of FAT).
To know where it should look for these executables, UEFI relies on *boot entries*, stored in NVRAM.
On linux, these entries can be accessed through the kernel in `/sys/firmware/efi/efivars`.
There is also a tool called `efibootmgr`, which I will talk about shortly, that makes managing the boot entries easier.

The entries in this NVRAM are used by the *UEFI Boot Manager*, which you can think of as a firmware level boot menu.
It can be configured by NVRAM variables, and it has the boot order and the entries for each EFI app.
You can define your entries explicitly, but it also can define them automatically.
In fallback mode, when it doesn't find the EFI apps defined in the boot entries, it will look at the EFI partitions, and tries to load `/EFI/BOOT/BOOT<arch>.EFI`
Fallback is mostly used for booting from external devices.
All it takes for a disk to be UEFI bootable is to have an EFI partition with at least one EFI image on it.

As long as it's executable by UEFI, you can put anything in the EFI parititon.
Usually the vendor ships the hardware with some applications already installed (usually in the `EFI/<vendor>` directory), like diagnostic and recovery tools, and also the EFI shell, which is exactly what it sounds like: a little shell you can use when booting fails for some reason.
Knowing how to navigate the EFI shell can be life-saving, when you can't boot your OS normally, and you only have to know about 3 things:

- You can use `-b` for paging (this is key, because without this, you can't even read the output of `help`)
- `map` for listing block devices and filesystems
- `FS<n>:` to use the n-th filesystem

When "inside" a filesystem, you can use `ls` and `cd` to navigate.
If you found your EFI image, just type it's path (you can use it's relative path) to start it.

# Secure Boot

And now we arrived at the main topic: secure boot.
The important thing to understand is that secure boot is not some evil plan by Microsoft, although it does make life harder if you don't use Windows, and you want secure boot enabled (or your employer wants it enabled).

Secure boot is a feature provided by UEFI, for making it harder to boot anything but the things you want your device to boot.
It does this by requiring the image (the EFI app) to be signed by your key, otherwise it won't start it.
It says nothing about Microsoft, it just provides a way to prevent unsigned images from executing.

The problem comes from the fact that Microsoft requires that the device should be able to use secure boot for it to be Microsoft certified.
Because vendors desperately need this arguably high status for their devices for them to be allowed to put the Microsoft stickers on them, they ship the hardware with Microsoft keys already installed.
Now if you don't own the hardware, and can't access the key database, you can only execute apps that were signed by Microsoft (and the vendor).
Of course if you own it, and you can access the key database, nothing stops you from adding your own keys and signing your own bootloader (or anything else).

Now if you are in the unfortunate situation of not being able to modify the key database, and you are forced to use secure boot, but you would, for some inapprehensible reason, use anything but Windows, reading the previous paragraphs must have left you pretty hopeless.
Signing the image is done by ECDSA, with the minimum key size of 256, which can take some time to crack.
Fortunately, there is an other way to circumvent the problem: by the help of Microsoft itself.

Microsoft was nice enough to also sign loaders for it's friends.
There are two distros I know of, which have their bootloaders signed: Ubuntu and Fedora.
So these two should start fine wihout any problem.
But what if you don't want to use an enterprise linux distro?
That's where *signed boot loaders* come into the picture.

# Preloader and Shim

There are two known signed bootloaders: preloader and shim.
I will only show preloader, because that's what I use, but the process should be similar with shim.

Preloader is a signed EFI app, that does one thing: calls your EFI executable.
That EFI executable can be anything, so you can call your bootloader with it.
(It should be possible to call directly your kernel, if you use it as an EFISTUB, but I'm not sure how to pass the kernel parameters to it with the preloader.)

It works like this: you put the preloader into your EFI partition, then you create a boot entry for it, and finally, you place your bootloader (or whatever) in the same folder, and rename it to `loader.efi` (this is important, because the preloader will search for a file with this exact name).

There is one last problem: Microsoft wouldn't sign something with their key, that launches arbitrary executables.
This is why preloader and shim use an allowlist, called Machine Owner Key list.
Your binary's hash has to be in the Machine Owner Key list, otherwise they won't start it, and you have to enroll your binary yourself.
If you are using Arch, you can just install the `preloader-signed` package from the AUR, which should work out of the box.
I will take this package for granted, so I won't discuss the process of enrolling the hash in the Machine Owner Key list, but you can find more information about it on the [Arch wiki](https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot#PreLoader).

After installing the `preloader-signed` package, you have to copy the Preloader and HashTool EFI images to your EFI partition.
This depends on your setup, but for me, it's `<efi_part>/EFI/grub`.

`# cp /usr/share/preloader-signed/{PreLoader,HashTool}.efi <efi_part>/EFI/grub`

Now copy the bootloader to the same folder, and rename it to `loader.efi`

And finally, add a new boot entry to the NVRAM (you can figure out the partition with `efibootmgr -v`):

`# efibootmgr --verbose --disk /dev/<disk> --part <partition> --create --label "<name>" --loader <efi_part>/EFI/grub/PreLoader.efi`

After this, you can change the boot order with the following command (use `efibootmgr -v` to get the entry numbers):

`# efibootmgr -o xxx,yyy,zzz...`

If everything went according to the plan, you should be able to boot into your OS with the preloader boot entry.
