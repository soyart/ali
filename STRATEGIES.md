# Using and implementing ALI

ALI itself is just a YAML spec - this leaves implementation details
to 3rd party installer implementation.

Below are some guidelines for both installer devs and users:

1. Allow partial manifest (allow undefined items)

   This might upset some functional programming people - but allowing
   some ALI items to be omitted actually makes it more useful for users.

   IF WE DO NOT allow partial manifest, then every resources/references
   used in a manifest item MUST also be defined in the manifest.

   For example, considering this scenario: creating a root filesystem.

   If we do not allow partial manifests, then we'd need to write this whole
   thing in order to create a root filesystem:

   ```yaml
   disks:
     - device: /dev/sda
     partitions:
        - label: root

    rootfs:
        device: /dev/sda1
        fstype: btrfs
        fsopts: -L rootfs
        mntopts: "compress:zstd:3"
   ```

   And this means `/dev/sda` will be formatted - any existing data will be destroyed,
   and there's no way around that except manual backups.

   However, if we allow partial manifest to be used in other items (undefined [`disks`](./ALI.md#key-disks) items),
   then we can use pre-existing devices on the system to serve as the root filesystem of the
   new Arch install, assuming that `/dev/sda1` already exists on the system:

   ```yaml
   rootfs:
     device: /dev/sda1
     fstype: btrfs
     fsopts: -L rootfs
     mntopts: "compress:zstd:3"
   ```

   The manifest above will just attempt to create a root filesystem on _some_ device `/dev/sda1`,
   failing only if it fails to do so, i.e. if there's no such device.

   Another benefits include the user ability to use ALI as _part_ of their installation process,
   and not the whole. They may at first use ALI to just partition the system, then manually configure
   something, before they switch back to ALI to automate some post-install configuration.

   For example, LVM and LUKS support in ALI is very primitive - if users need more advanced options,
   then they can pre-create the DM devices, and then just use ALI to create filesystems on those
   devices.

   This other benefits of allowing partial manifest is that if a previous installation failed,
   we can use ALI to apply only the rest of unconsumed items by removing succesful items applied
   in the previous run.

2. Create tools to work with manifest

   Developers can also write a new program that just works on parts of the manifest, e.g. a disk formatter
   that will just read the manifest and only apply block device-related items to the system

   Other tools may include validation tools, or a visualization tool.

3. Emulate full-blown installers with shell scripts

   Users and developers are encouraged to deploy their own shell scripts to perform some delicate tasks
   that ALI does not cover, e.g. bootloader configuration or DE setup.

   These shell scripts can be executed as items in keys [`chroot`](./ALI.md#key-chroot) or
   [`postinstall`](./ALI.md#key-postinstall), e.g. to configure WireGuard networks, etc.

   This gives almost endless possibilities with ALI 2-phase shell execution of user-defined commands.
