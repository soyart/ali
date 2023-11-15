# ALI

```text
   ___   __   ____
  / _ | / /  /  _/
 / __ |/ /___/ /
/_/ |_/____/___/
```

ALI (Aux Linarch Installer) is a minimal declarative,
manifest-based Arch Linux installer.

## Quickstart

- [Documentation](./ALI.md)

  ALI specification documentation

- [ali-rs](https://github.com/soyart/ali-rs)

  ALI implementation with validation and hooks

- [ALI strategies, ideas, etc.](./STRATEGIES.md)

  ALI mindset

- [ALI manifest examples](./examples/)

  ALI YAML examples for different scenarios

> This repository only hosts the specification of ALI,
> i.e. what an installer should do based on the manifest,
> but without the actual implementations.
> Also, this specification does not specify how to validate the
> manifest, leaving the question of validation entirely to the
> implementations.

## About ALI

ALI is just a YAML specification. It specifies how to install and configure
a new Arch Linux system from scratch.

The spec came from generalizing Arch Linux installation steps into what
we call [ALI stages](./ALI.md#application-of-manifest).

Then, we try to come up with the most simple,
straightforward, and flexible way to compose those stages.

Some details that are present in every Arch install (e.g. locales and `fstab`)
get default values with no way to configure it from ALI.

Only what really matter are put in the ALI specification.

If users wish to customize the system beyond what the spec specifies,
they can do so with the best plugin system ever, shell commands - ALI supports
arbirary shell commands to help extend the customizability.

The result is a mix of high and low touch installer. It is high touch approach
because users would need to think out about how they want to install their
systems (partitioning, etc.), and it is low touch in that once you get a working
config, you can later use it to reproduce your subsequent builds.

And so ALI targets advanced Arch Linux users who know exactly what they
are doing, but are too lazy with the details or looking up Arch Wiki
every time they want a fresh yet similar system.

## Arch Linux installation steps (ALI stages)

See [ALI's Application of manifest section](./ALI.md#application-of-manifest)

## Features

### Covered by ALI manifest keys

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

  This can be used to perform in-jail configuration,
  e.g. populating `mkinitcpio.conf` and generate a new boot image,
  or when installing bootloader.

- [User's post-install scripts](./ALI.md#key-postinstall) after `arch-chroot`

  This can be used to set up stuff post-chroot, e.g. when
  creating a new `efibootmgr` entries after a successful installation.

### Not officially covered by ALI manifest keys

> Note: Most if not all of these list items below
> can actually be done with shell commands/scripts.
>
> Warn: You might need to setup `systemd-networkd`
> before rebooting to the new system

- Networking

  note: network interfaces and DNS upstream is supported by [ali-rs implementation](https://github.com/soyart/ali-rs)

- `mkinitcpio` and boot images

  note: popular templates supported by [ali-rs implementation](https://github.com/soyart/ali-rs)

- User management

- systemd services

- Bootloaders

## Comparison with cloud-init or autoinstall

Unlike cloud-init and its extension autoinstall, ALI is just a standard.

ALI is also much more simple - and does not currently have features
about user management, crypto keys, or enabling systemd services,
although these things can be easily imitated via the arbitary shell commands.

The currently existing implementation [`ali-rs`](https://github.com/soyart/ali-rs)
is also very different from cloud-init or autoinstall in that it's just a normal
program, and not something to be loaded at boot time.

ali-rs does have extra functionality beyond ALI,
like basic [networking setup](https://github.com/soyart/ali-rs/blob/master/HOOKS.md#quicknet),
and [`mkinitcpio.conf`](https://github.com/soyart/ali-rs/blob/master/HOOKS.md#mkinitcpio)

ali-rs also requires a working Linux system with access to [`pacman`
and other basic GNU/Linux utils](https://github.com/soyart/ali-rs/blob/master/src/constants.rs)
for installing the system.
