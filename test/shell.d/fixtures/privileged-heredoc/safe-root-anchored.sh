unit=agent0s-agent.service

# "/etc/systemd/system/$unit" is a path, but one anchored where root already
# owns everything, so paths=none is the truthful declaration -- the check must
# not demand paths=unit here.
# agent0s:heredoc-expands paths=none -- $unit is a unit name interpolated only into absolute /etc paths
cat >"/etc/systemd/system/$unit" <<UNIT
[Service]
ExecStart=/usr/bin/agent0s-agent
ExecStopPost=/usr/bin/rm -f /etc/systemd/system/$unit
UNIT
