title   {{ ENTRY_TITLE }}
linux   {{ VMLINUZ }}
initrd  {{ UCODE }}
initrd  {{ INITRAMFS }}

# Kernel parameters
options loglevel=3
options rd.luks.options={{ LUKS_OPTS }}
options rd.luks.name={{ LUKS_UUID }}={{ CRYPTROOT }}
options root={{ CRYPTROOT }} ro

# Get offset for Btrfs swapfile: https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate#Hibernation_into_swap_file
options resume={{ RESUME }}
options module_blacklist={{ BLACKLIST }}