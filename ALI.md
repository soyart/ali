# ALI manifest specifications `v0.0.1`

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

## Application of manifest

Order of manifest application

| Preparing mountpoints                                  | Installing `base` | Installing packages         | Hard-coded chroot                                       | User-defined chroot     | User-defined post-install         |
| ------------------------------------------------------ | ----------------- | --------------------------- | ------------------------------------------------------- | ----------------------- | --------------------------------- |
| [`disks`](#key-disks)                                  | -                 | [`pacstrap`](#key-pacstrap) | [`hostname`](#key-hostname),[`timezone`](#key-timezone) | [`chroot`](#key-chroot) | [`postinstall`](#key-postinstall) |
| [`dm`](#key-dm)                                        |                   |                             |                                                         |                         |                                   |
| [`rootfs`](#key-rootfs),                               |                   |                             |                                                         |                         |                                   |
| [`swap`](#key-swap)                                    |                   |                             |                                                         |                         |                                   |
| [`fs`](#key-fs)                                        |                   |                             |                                                         |                         |                                   |
| Mount `rootfs`, `swap`, and other `fs` to `/alitarget` |                   |                             |                                                         |                         |                                   |

Although ALI does not specify steps, common sense tells us that the installer
would apply ALI items in some crude order:

- Preparing mountpoints (user-defined)

  This is the 1st thing the installer does - prepare our system mountpoints.
  The installer would have to create a new partition table and partitions
  [(key `disks`)](#key-disks), then create any DM devices [(key `dm`)](#key-dm),
  then creating filesystems on those devices as well as mounting them to specified
  locations (keys [`rootfs`](#key-rootfs), [`swap`](#key-swap), and [`fs`](#key-fs)).

- Installing Arch Linux `base` with `pacstrap(8)` (hard-coded)

  After system mountpoints are ready, the installer should now install `base`
  meta-package to the mountpoints, making those mountpoint ready to be `chroot(1)`ed into

- Installing Arch Linux packages with `pacstrap(8)` (user-defined)

  Arch packages from key `pacstrap` can then be installed to those mountpoints to
  bootstrap a minimal Arch system.

- Configure the system with `chroot(1)` (hard-coded)

  After the basic system was freshly installed, the installer would `chroot(1)` into
  the new system, and performs some hard-coded tasks such as setting up locales
  and `fstab(5)`.

- Configure the system with `chroot(1)` (user-defined)

  After the installer finishes with its hard-code commands inside `chroot(1)`,
  the installer will then executes user-defined shell commands from key `chroot`.
  After this is done, the installer exits.

- Post-install configuration of the system outside `chroot(1)` (user-defined)

  Now that the installer exits from `chroot(1)`, the installer would execute the last
  items in the manifest: the [`postinstall` key](#key-postinstall).

  Each item in the list here will be executed in the live system, so beware of the file
  paths in here (unless users prepend `chroot /alitarget` in each list item).

  This part can be used to install a bootloader.

# Keys reference

> Note: only [key `rootfs`](#key-rootfs) is required.

## Key `hostname`

The hostname of the installed machine

## Key `timezone`

A path to timezone file (in `/usr/share/zoneinfo`) to be linked to `/etc/localtime`

E.g., `Asia/Bangkok` will link `/usr/share/zoneinfo/Asia/Bangkok` to `/etc/localtime`

## Key `disks`

`disks` defines how partition tables are created on the disks.

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

Extra filesystem setups

- `fs.mnt`

The mount point **on the installed system**.

If this field is omitted, the filesystem will be created, but not mounted.

- `fs.mntopts`

The mount option for the filesystem

- `fs.device`, `fs.fsopts`, `fs.mntopts`

These fields have identical behaviors to [`rootfs`](#key-rootfs)

## Key `swap`

Swap devices, as an array of strings pointing to valid block devices

## Key `pacstrap`

A list of packages to be installed to new system before `arch-chroot`

## Key `chroot`

A list of commands to be run during `arch-chroot` after some ainyi had
set up the locales, system time, and other boring stuff

## Key `postinstall`

A list of commands to be run after ainyi had exited from `arch-chroot`.

After this section, the script stops, and users must proceed from here
