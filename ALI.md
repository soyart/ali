# ALI manifest specifications `v0.0.1`

```text
   ___   __   ____
  / _ | / /  /  _/
 / __ |/ /___/ /
/_/ |_/____/___/
```

> ## Note: block storage validation
>
> ALI current specifications only specify the parameters for _creation_
> of those block devices, but not the validation. The validation scheme is
> free for ALI implementations to choose. The aliases for these keys are
> also up to the implementations, unless explicitly defined in the specs.
>
> This means that implementations can be very different.
> Some will happily do everything in the manifest without validating anything,
> Some will validate but still overwrite data on the old system,
> and some will not attempt to do anything if the manifest conflicts with the state
> of the system (i.e. manifest specifies new partition that already exists)
>
> This is to reduce the complexity of the specifications, allowing us
> to build a quick blind implementations, or super-safe implementations,
> all sharing the same simple specs.

# Overview

Each ALI manifest contains _ALI items_, or a _thing_ that
we'll need to address when installing Arch Linux.

These items are organized into key groups (sometimes just key),
with each different key group defined under different top-level YAML keys.

Some key group will only have 1 item, e.g. the [`rootfs`](#key-rootfs) key.

Each item in a key will have its own structure, as outlined in the spec.

Most items are declarative, i.e. the ordering of its YAML subkeys are
irrelevant. Some items are procedural, as with key [`dm`](#key-dm),
[`chroot`](#key-chroot), and [`postinstall`](#key-postinstall).

## ALI stages

| Preparing mountpoints             | Installing `base` and packages | Boring part                 | Hard-coded chroot               | User-defined chroot     | User-defined post-install         |
|-----------------------------------|--------------------------------|-----------------------------|---------------------------------|-------------------------|-----------------------------------|
| [`disks`](#key-disks)             | [`pacstrap`](#key-pacstrap)    | [`hostname`](#key-hostname) | [`timezone`](#key-timezone)     | [`chroot`](#key-chroot) | [`postinstall`](#key-postinstall) |
| [`dm`](#key-dm)                   |                                |                             | [`rootpasswd`](#key-rootpasswd) |                         |                                   |
| [`rootfs`](#key-rootfs),          |                                |                             |                                 |                         |                                   |
| [`swap`](#key-swap)               |                                |                             |                                 |                         |                                   |
| [`fs`](#key-fs)                   |                                |                             |                                 |                         |                                   |
| [`mountpoints`](#key-mountpoints) |                                |                             |                                 |                         |                                   |
|                                   |                                |                             |                                 |                         |                                   |
| `stage-mountpoints`               | `stage-bootstrap`              | `stage-bootstrap`           | `stage-chroot_ali`              | `stage-chroot_user`     | `stage-postinstall_user`          |

# Manifest keys reference

> Note: only [key `rootfs`](#key-rootfs) is a required key.
> Specifying only `rootfs` will get you a new system with `base` installed
> with `stage-chroot_ali` modifications.

## Key `hostname`

The hostname of the installed system. Default values depend on implementations.

## Key `timezone`

A path to timezone file (in `/usr/share/zoneinfo`) to be linked to `/etc/localtime`

E.g. `Asia/Bangkok` will link `/usr/share/zoneinfo/Asia/Bangkok` to `/etc/localtime`

## Key `disks`

Changes to be made to disks (partitioning). This key is destructive - any disk specified in an
entry will be wiped clean with new partition table.

> If you wish to preserve data on a disk while using it in the new system,
> prepare the new partitions manually before hand.
>
> Then, you could specify the newly created partition path in either of the keys
> [`dm`](#key-dm), [`rootfs`](#key-rootfs), [`fs`](#key-fs), or [`swap`](#key-swap).

- `disks.device`

  The device file path of the disk

- `disks.device.table.`

  Partition table of the disk, e.g. `gpt` or `dos`.

  > `dos` is aliased to `msdos`, `ms-dos`, `mbr`

- `disks.device.partitions`

  Partitions in the tables. The order of the partitions is the same as that in the manifest

- `disks.device.partitions.label`

  Nothing. It is here for debugging.

  - `disks.device.partitions.size`

  The partition size, i.e. `3G` for 3 gigabytes, and `200M` for 200 megabytes.

  The last partition gets special treatment: this field can be left omitted and
  ainyi will treat it as one large partition that fills to the disk's last block.

  - `disks.device.partitions.type`

  The [Linux partition type code](https://tldp.org/HOWTO/Partition-Mass-Storage-Definitions-Naming-HOWTO/x190.html).

  If omitted, defaults to `linux` (`83`). Some available aliases are:

  ```
  Aliases:
   linux          - 83
   swap           - 82
   extended       - 05
   uefi           - EF
   raid           - FD
   lvm            - 8E
   linuxex        - 85
  ```

## Key `dm`

`dm` defines how Linux device mappers should be created before creating root filesystem.

Its item value is an array, and like GitHub Actions workflow's `steps`, each `dm` entry
will be processed in the order that they appear in the manifest.

Each entry must have a `type` key, with 2 possible values: `luks` and `lvm`.

The commands are ordered, i.e. if you have:

```yaml
dm:
  # 1st DM item is LUKS
  - type: luks
    device: /dev/vda2
    name: cryptroot
    key: mysupersecretkey

  # 2nd DM item is LVM
  - type: lvm
    pvs:
      - /dev/mapper/cryptroot
    vgs:
      - name: archvg
        pvs:
          - /dev/mapper/cryptroot
    lvs:
      - name: swaplv
        size: 8G
      - name: rootlv
        vgs:
          - archvg
```

Then the LUKS device will be created and opened,
before the LVM volumes get created on top of it

Likewise, if you have:

```yaml
dm:
  # 1st DM item is LVM
  - type: lvm
    pvs:
      - /dev/vda2
      - /dev/nvme0n1p1

    vgs:
      - name: archvg
        pvs:
          - /dev/vda2
    lvs:
      - name: swaplv
        size: 8G
      - name: rootlv
        vg: archvg

  # 2nd LVM item is LUKS
  - type: luks
    device: /dev/archvg/rootlv
    name: cryptroot
    key: mysupersecret
```

Then the LVM volumes will be created first, and LUKS on top of it

## LUKS device

LUKS devices are encrypted with a key, which in ALI is specified
under key `luks.key`. Only clear-text passphrase is supported.

> If you need more flexibility, you can prepare LUKS devices beforehand
> and then have other manifest items point at the pre-created devices.

The example below will create 2 LUKS devices, each having different
keys.

```yaml
dm:
  - type: luks
    device: /dev/archvg/rootlv
    name: cryptroot
    key: secretkey-root

  - type: luks
    device: /dev/archvg/swaplv
    name: cryptswap
    key: secretkey-swap
```

## Key `rootfs`

`rootfs` specifies the root filesystem of the installed system.

- `rootfs.device`

  Path to device file, e.g. `/dev/vda`, `/dev/nvme0n1p2`, `/dev/mapper/myvg`

- `rootfs.fstype`

  The filesystem type, e.g. `ext4` and `btrfs`

  ```yaml
  rootfs:
    device: /dev/nvme0n1p1
    fstype: btrfs
  ```

  The above manifest will result in this shell command:

  ```shell
  mkfs.btrfs /dev/nvme0n1p1
  ```

- `rootfs.fsopts` (Optional)

  The options for the filesystem, at the time of creation

  ```yaml
  rootfs:
    device: /dev/mapper/mylvm
    fstype: btrfs
    fsopts: -L rootfs
  ```

  The above manifest will result in this shell command:

  ```shell
  mkfs.btrfs -L rootfs /dev/nvme0n1p1
  mount /dev/mapper/mylvm /alitarget
  ```

- `rootfs.mntopts` (Optional)

  The filesystem mount options for the 1st mount (before `arch-chroot` steps)

  ```yaml
  rootfs:
    device: /dev/nvme0n1p1
    fstype: btrfs
    fsopts: -L rootfs
    mntopts: compress:zstd:3
  ```

  The above manifest will result in this shell command:

  ```shell
  mkfs.btrfs -L rootfs /dev/nvme0n1p1
  mount -o compress:zstd:3 /dev/nvme0n1p1 /alitarget
  ```

## Key `fs`

Creates **non-root** filesystems

> For root filesystem, see [key `rootfs`](#key-rootfs)

- `device`

  Device to create filesystem on

- `fstype`

  Type of filesystem to create, e.g. `ext4`, `xfs`, `btrfs`

- `fsopts` (Optional)

  Options to pass to `mkfs`

```yaml
fs:
  # mkfs.vfat -F32 /dev/sda1
  - device: /dev/sda1
    fstype: vfat
    fsopts: -F32

  # mkfs.btrfs /dev/sda2
  - device: /dev/sda2
    fstype: btrfs
```

## Key `mountpoints`

Defines **non-root** mountpoints on the new system,
as well as in the new system's `fstab` entries.

- `device`

  Path to source filesystem to mount

- `dest`

  Path to destination mountpoint

- `mntopts` (Optional)

  Mount options to pass to `mount`

```yaml
mountpoints:
  # mount /dev/sda1 /{install_mnt}/boot
  # which will be written to fstab as /boot
  - device: /dev/sda1
    dest: /boot
    mntopts:

  # mount /dev/sda2 -o compress:zstd:3 /data
  - device: /dev/sda2
    dest: /data
    mntopts: compress:zstd:3
```

## Key `swap`

Swap devices, as an array of strings pointing to valid block devices

Example:

```yaml
swap:
  - /dev/nvme0n1p2
  - /dev/sda3
```

This will create swap on 2 devices, mount them, and later write these
devices to new system's `fstab` as swap devices:

```shell
mkswap /dev/nvme0n1p2
mkswap /dev/sda3

swapon /dev/nvme0n1p2
swapon /dev/sda3
```

## Key `pacstrap`

A list of packages to be installed to new system before `arch-chroot`

Any commands provided by packages declared and successfully installed from
this key should later be available to use in key [`chroot`](#key-chroot)

## Key `chroot`

A list of commands to be run during `arch-chroot` after some ALI installer
had set up the locales, system time, and other boring stuff

## Key `rootpasswd`

Hashed password for user `root`. Do not enter plaintext password here -
instead, use the following commands to generate hash password:

```shell
openssl passwd -6 -salt 'mysalt' 'yourpass' # SHA-512
openssl passwd -5 -salt 'mysalt' 'yourpass' # SHA-256
```

[You can use this StackOverflow article to alternatively generate a hashed Linux
password.](https://unix.stackexchange.com/questions/81240/manually-generate-password-for-etc-shadow).

The password will be applied with the following shell command
run in `chroot` by the installer:

```shell
echo "root:${hashedPassword}" | chpasswd -e
```

## Key `postinstall`

A list of commands to be run after ainyi had exited from `arch-chroot`.

After this key, the installer exits, and users must proceed from here
