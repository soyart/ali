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

  The partition type code. If omitted, defaults to `Linux` (`83`)

## Key `dm`

`dm` defines how Linux device mappers should be created before creating root filesystem.
Its values is an array, like GitHub Actions workflow's `steps` - each `dm` entry
will be processed in the order that they appear in the manifest.

Each entry must have a `type` key, with 2 possible values: `luks` and `lvm`

The commands are ordered by the keys, i.e. if you have:

```yaml
dm:
  - type: luks
    device: /dev/vda2
    name: cryptroot

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

Then the LUKS device will be created and opened (`luksOpen`),
before the LVM volumes get created on top of it

Likewise, if you have:

```yaml
dm:
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

  - type: luks
    device: /dev/archvg/rootlv
    name: cryptroot
```

Then the LVM volumes will be created first, and LUKS on top of it

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
    fsflags:
      - -L rootfs
  ```

  The above manifest will result in this shell command:

  ```shell
  mkfs.btrfs -L rootfs /dev/nvme0n1p1
  ```

- `rootfs.mntopts` (Optional)

  The filesystem mount options for the 1st mount (before `arch-chroot` steps)

  ```yaml
  rootfs:
    device: /dev/nvme0n1p1
    fstype: btrfs
    fsflags:
      - -L rootfs
    mntopts: compress:zstd:3
  ```

  The above manifest will result in this shell command:

  ```shell
  mkfs.btrfs -L rootfs /dev/nvme0n1p1
  mount -o compress:zstd:3 /dev/nvme0n1p1
  ```

## Key `fs`

Extra filesystem setups

- `fs.mnt`

The mount point **on the installed system**.

- `fs.mntopts`

The mount option for the filesystem

- `fs.device`, `fs.fsopts`, `fs.mntopts`

Identical behaviors to `rootfs` keys

## Key `swap` (optional)

Swap devices, as an array of strings pointing to valid block devices

## Key `pacstrap`

A list of packages to be installed to new system before `arch-chroot`

## Key `chroot`

A list of commands to be run during `arch-chroot` after some ainyi had
set up the locales, system time, and other boring stuff

## Key `postinstall`

A list of commands to be run after ainyi had exited from `arch-chroot`.

After this section, the script stops, and users must proceed from here
