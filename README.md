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

See also: [ALI use mindset and strategies](./STRATEGIES.md)

## Arch Linux installation steps

See [ALI's Application of manifest section](./ALI.md#application-of-manifest)

# Disclaimer

As of now, it does:

- Block device initialization and filesystems

  i.e. creating filesystems, swaps, or other software-defined storage

  > Note: no swap will be created
  > for [Btrfs](https://man.archlinux.org/man/btrfs.5#SWAPFILE_SUPPORT)

- Basic package installation with `pacstrap(8)`

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