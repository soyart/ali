title   {{ ENTRY_TITLE }}
linux   {{ VMLINUZ }}
initrd  {{ UCODE }}
initrd  {{ INITRAMFS }}

# Kernel parameters
options loglevel=3
options root={{ ROOTDEV}} ro
options {{ RESUME_DEV }}
options module_blacklist={{ BLACKLIST }}