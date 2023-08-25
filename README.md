# ALI

ALI (Aux Linarch Installer) is a minimal declarative,
manifest-based Arch Linux installer,
with [YAML manifest specification](./ALI.md).

This repository only hosts the specification of ALI,
i.e. what an installer should do based on the manifest,
but without the actual implementations.

> A WIP Rust implementation is available
> at [`ali-rs`](https://github.com/soyart/ali-rs)

The specification is very minimal, and it will still require
that the user or the implementations do some extra work, like
installing and configuring bootloader.

Also, this specification does not specify how to validate the
manifest, leaving the question of validation entirely to the
implementations.

# Disclaimer

As of now, it does:

- Block device initialization and filesystems

  i.e. creating filesystems, swaps, or other software-defined storage

  > Note: no swap will be created
  > for [Btrfs](https://man.archlinux.org/man/btrfs.5#SWAPFILE_SUPPORT)

- Basic package installation with `pacstrap`

- Boring steps

  Locale and system time, `genfstab`, etc.

- User's post-scripts

- Exit to the live system

It does NOT:

- Setup networking

  > Warn: You might need to setup `systemd-networkd` before reboot to new system

- Update `mkinitcpio.conf`

- Install and configure bootloader

A lot of options are hard-coded as hard defaults, such as:

- Locale will always be `en_US.UTF-8`

## Flows

1. ALI installer parses the YAML definition of the install

2. ALI installer inspects the local machine if it has the required resources:

   > Note: the user-supplied post-scripts are not inspected.
   > Users must be sure to install the programs required by their
   > post-scripts in the `packages` or `aur` keys first.

   - Device files

     As per the specification, e.g. disks and network

   - `arch-chroot`

     Required for all installations

   - `mkfs.<fs>`

     Required for the filesystem defined in the `rootfs` field

3. ALI installer creates a new partition table on the target `disks`

4. ALI installer creates either

   - LUKS devices (defined in `dm.lvms`)

   - LVM devices (defined in `dm.luks`)

   - Filesystems (defined in `rootfs`, `fs`, and `swap`)

   Depending on the manifest

5. ALI installer installs the base system using `pacstrap` (defined in key `pacstrap`)

6. ALI installer does some boring stuff

> e.g. `/etc/fstab`, `/etc/localtime`, `/etc/hostname`, locales

7. ALI installer executes commands inside a chroot, defined in key `chroot`

8. ALI installer exits from chroot, and executes commands defined in key `postinstall`
