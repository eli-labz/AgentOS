hl.on("hyprland.start", function()
  -- Slow app launch fix -- set systemd vars before starting session services.
  hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1)")
  hl.exec_cmd("dbus-update-activation-environment --systemd --all")

  hl.exec_cmd("agent0s-launch-shell")
  hl.exec_cmd("agent0s-provision-first-run")
  hl.exec_cmd("agent0s-powerprofiles-init")
  hl.exec_cmd(o.launch("agent0s-hyprland-monitor-watch"))
  hl.exec_cmd(o.launch("udiskie --automount --no-notify --no-tray"))

  -- Run post-boot hooks after startup config has loaded.
  hl.exec_cmd("sleep 2 && agent0s-hook post-boot")
end)
