echo "Unpack the initramfs synchronously so Plymouth survives early boot"

# Kernel 7.1 unpacks the initramfs asynchronously, which races /init: the
# early /proc, /sys, /dev, and /run mounts fail while unpacking settles, so
# plymouthd exits when it can't read /proc/cmdline and encrypted boots fall
# back to an unthemed text LUKS prompt. Force synchronous unpacking until the
# race is fixed upstream. The packaged agent0s-defaults.conf now carries the
# same parameter for fresh installs.

if agent0s-cmd-present limine-mkinitcpio &&
  [[ -f /etc/limine-entry-tool.d/agent0s-defaults.conf ]] &&
  ! grep -rqs "initramfs_async" /etc/limine-entry-tool.d/ /etc/default/limine; then
  echo 'KERNEL_CMDLINE[default]+=" initramfs_async=0"' |
    sudo tee -a /etc/limine-entry-tool.d/agent0s-defaults.conf >/dev/null

  sudo limine-mkinitcpio
fi
