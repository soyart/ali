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

   And this means `/dev/sda` will be formatted - any existing data will
   be destroyed, and there's no way around that except manual backups.

   However, if we allow partial manifest to be used in other items (undefined
   [`disks`](./ALI.md#key-disks) items), then we can use pre-existing devices
   on the system to serve as the root filesystem of the new Arch Linux install,
   assuming that `/dev/sda1` already exists on the system:

   ```yaml
   rootfs:
     device: /dev/sda1
     fstype: btrfs
     fsopts: -L rootfs
     mntopts: "compress:zstd:3"
   ```

   The manifest above will just attempt to create a root filesystem on _some_
   device `/dev/sda1`, failing only if it fails to do so, i.e. if there's no such device.

   Another benefits include the user ability to use ALI as _part_ of their installation process,
   and not the whole. They may at first use ALI to just partition the system,
   then manually configure something, before they switch back to ALI to automate some
   post-install configuration.

   For example, LVM and LUKS support in ALI is very primitive -
   if users need more advanced options, then they can pre-create the DM devices,
   and then just use ALI to create filesystems on those devices.

   This other benefits of allowing partial manifest is that if a previous installation failed,
   we can use ALI to apply only the rest of unconsumed items by removing succesful items applied
   in the previous run.

2. Emulate full-blown installers with shell scripts

   Users and developers are encouraged to deploy their own shell scripts to perform
   some delicate tasks that ALI does not cover, e.g. bootloader configuration or DE setup.

   These shell scripts can be executed as items in keys [`chroot`](./ALI.md#key-chroot) or
   [`postinstall`](./ALI.md#key-postinstall), e.g. to configure WireGuard networks, etc.

   This gives almost endless possibilities with ALI 2-phase shell execution of user-defined commands.

3. Create tools to work with manifest

   Developers can also write a new program that just works on parts of the manifest,
   e.g. a disk formatter that will just read the manifest and only apply block device-related
   items to the system

   Other tools may include validation tools, text processing tools, or a visualization tool.

   Developers can also develop hooks or pre-defined functions to help facilitate users
   configuration, i.e. more like ALI extension.

4. Provide configuration templates

   These config files should contains tokens (like GitHub Actions `{{ secrets.GITHUB_TOKEN }}`)
   that we can use to programatically operate on.

## Tooling example: custom command parsers

For example, an imaginary ALI installer `alice` could have added non-ALI specs
such that if commands in `chroot` and `postinstall` keys start with `#`,
they are special non-shell commands and must be parsed by the installer to do
something else.

Let's say this `alice` installer provides 3 custom commands, also called tags
in `alice` terminology:

- `#replace-kv`

  A simple text replacement tools with, key-value.

  Syntax: `#replace-kv <KEY> <VALUE> <FILENAME> [OUTPUT]`

  Action: Replaces key `KEY`'s value with `VALUE` and writes to `OUTPUT`.
  If `OUTPUT` is omitted, `FILENAME` will be the destination.

  Examples:

  - Configuring `systemd-boot` entry

    Overwrites key `GRUB_CMDLINE_LINUX_DEFAULT` value with `vultr root=/dev/archvg/rootlv ro`
    on file `/alitarget/boot/loader/entries/default.conf` in `postinstall`.

    ```yaml
    postinstall:
      - '#replace-kv GRUB_CMDLINE_LINUX_DEFAULT "vultr root=/dev/archvg/rootlv ro" /alitarget/boot/loader/entries/default.conf'
    ```

    > Note that because this custom command runs after `alice` exits from chroot, so
    > the path to target files will have to be prepended with `/alitarget` mountpoint.
    >
    > Also, because `OUTPUT` is omitted, the output file will be written to `FILENAME`.

  - Configuring `sshd` port

    Sets `sshd` listening port to `7522`, and disables passwords

    ```yaml
    chroot:
      - "#replace-kv PORT 7522 /etc/ssh/sshd_config"
      - "#replace-kv PasswordAuthentication no"
    ```

- `#replace-token`

  Like `#replace-kv`, but works on tokens

  Syntax: `#replace-token <TOKEN> <VALUE> <TEMPLATE> [OUTPUT]`

  Action: Replaces every token `TOKEN` with `VALUE`

  Examples:

  - Configures nameserver in `resolv.conf`

    Let's say we have our template of `resolve.conf` stored at
    `https://example.com/templates/resolv.conf` with this content:

    ```
    nameserver {{ dns_host }}
    nameserver 127.0.0.1
    ```

    Then we can use the following manifest to replace `{{ dns_host }}`
    with `1.1.1.1`:

    ```yaml
    postinstall:
      - "#replace-token dns_host 1.1.1.1 https://example.com/templates/resolv.conf /alitarget/etc/resolv.conf"
    ```

- `#quicknet`

  Sets up a simple DHCP and DNS on an interface with `systemd-networkd`

  Syntax: `#quicknet [dns <DNS_UPSTREAM>] <INTERFACE>`

  Action: Writes a config to `/etc/systemd/network/00-quicknet-{INTERFACE}.conf`

  Examples:

  - Configure a simple network interface:

    DHCP on `ens3` with DNS upstream at `9.9.9.9`

    ```yaml
    postinstall:
      - "#quicknet ens3 dns 9.9.9.9"
    ```
