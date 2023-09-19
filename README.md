# ALI

```text
   ___   __   ____
  / _ | / /  /  _/
 / __ |/ /___/ /
/_/ |_/____/___/
```

ALI (Aux Linarch Installer) is a minimal declarative,
manifest-based Arch Linux installer.

This repository provides:

- [ALI specifications](./ALI.md)

- [ALI strategies, ideas, etc.](./STRATEGIES.md)

> This repository only hosts the specification of ALI,
> i.e. what an installer should do based on the manifest,
> but without the actual implementations.
> Also, this specification does not specify how to validate the
> manifest, leaving the question of validation entirely to the
> implementations.
>
> A WIP Rust implementation is available
> at [`ali-rs`](https://github.com/soyart/ali-rs)

See also: [ALI YAML examples](./examples/)

## Arch Linux installation steps

See [ALI's Application of manifest section](./ALI.md#application-of-manifest)

## Features

### Covered by ALI

- Block device and mountpoint initialization

  - [partitioning](./ALI.md#key-disks)

  - [filesystems](./ALI.md#key-rootfs), [swaps](./ALI.md#key-swap), and [other software-defined storage](./ALI.md#key-dm)

  - [mounts](./ALI.md#key-fs)

- [Packages installation](./ALI.md#key-pacstrap) with `pacstrap(8)`

- Boring steps

  - locale (UTF-8 English)

  - [system time](./ALI.md#key-timezone)

  - `genfstab`

- [User's commands inside `arch-chroot`](./ALI.md#key-chroot)

  - e.g. `mkinitcpio`

- [User's post-install scripts](./ALI.md#key-postinstall) after `arch-chroot`

  - e.g. `efibootmgr`

### Not covered by ALI

- Setup networking

  > Warn: You might need to setup `systemd-networkd` before reboot to new system

- Configure `mkinitcpio.conf`

- Install and configure bootloader
