# File layout

How `agent0s/` is organized and where everything ends up on an installed
system.

## Mental model

Two Arch packages are built from this one repo (PKGBUILDs live in the
separate `omarchy-pkgs` repository, under `pkgbuilds/`):

- **`agent0s`** — runtime binaries (`bin/`, including `bin/agent0s-dev-*`),
  install/finalize scripts (`install/`), migrations, themes, and the
  Quickshell desktop (`shell/`). Depends on `agent0s-settings`.
- **`agent0s-settings`** — everything that has to be on the target *before*
  the agent0s package installs (specifically before `useradd -m` and the
  limine bootloader install): all `/etc/skel/**`, `/etc/` drop-ins,
  package-owned system files under `/usr/share` and `/usr/lib`, fonts,
  plymouth theme, sddm theme, branding, plus the limine/snapper configs
  (mkinitcpio hooks, limine-entry-tool drop-ins, snapper template, the
  `default/limine/` and `default/snapper/` trees, and the boot/snapshot
  story end-to-end). Also ships the three debug binaries
  (`agent0s-debug`, `agent0s-debug-idle`, `agent0s-upload-log`) needed by
  the live ISO env.

Two other packages live in `omarchy-pkgs` but stand alone:
`omarchy-keyring` (GPG keys for pacman) and `omarchy-nvim` (the Neovim
setup; independently seeds `/etc/skel`).

Some trees ship in neither package and exist only in the repo: `manual/`
(user manual chapters), `agents/skills/` (contributor task guides), `docs/`,
`test/`, and `plans/`.

Three layers populate `$HOME`:

1. **Seed** — `agent0s-settings` ships static defaults to `/etc/skel/`.
   Arch's `useradd -m` copies that tree into a new user's `$HOME` at user
   creation. This is the only mechanism that touches a brand-new user's home
   for these files.
2. **Finalize** — `agent0s-provision-user` (routed as `agent0s finalize
   user`) runs once per user and handles the things `/etc/skel` can't do
   because they need `$HOME` expansion, the live `$AGENT0S_PATH`, or runtime
   detection of system state.
3. **Resync** — `agent0s-reinstall-configs` is the explicit, destructive
   command for an existing user to clobber their configs back to shipped
   defaults.

`/etc/skel` only fires at user creation. Existing users picking up new
defaults must use the resync command.

Deferred-provisioning installs (`agent0s-apply-system --defer-provisioning`)
create no user at all: the ISO leaves `/var/lib/agent0s/provisioning/pending`
behind, which arms `agent0s-provision-owner.service` (shipped from
`install/provisioning/`, alongside the factory-reset finish unit and
`setup-form.sh`). On first boot `bin/agent0s-provision-owner` creates the
user on tty1 and runs the finalize step itself.

Current generated theme state lives under
`~/.local/state/agent0s/current/`. Keep `~/.config/agent0s/` for files a user
may intentionally version in a dotfile manager, such as user themes, hooks,
shell layout, plugins, and themed template overrides.

## Build-time map (repo → installed paths)

```
agent0s/                            built into          installed at
─────────────────────────           ──────────────      ────────────────────────────────────

bin/agent0s-*                  ──►  agent0s             /usr/bin/agent0s-*
                                                        (and symlinks in /usr/share/agent0s/bin/)
bin/agent0s-debug,
bin/agent0s-debug-idle,
bin/agent0s-upload-log         ──►  agent0s-settings    /usr/bin/  (needed before agent0s is installed)

default/libalpm/hooks/*.hook
                                ──►  agent0s             /usr/share/libalpm/hooks/*.hook

install/**                     ──►  agent0s             /usr/share/agent0s/install/
migrations/**                  ──►  agent0s             /usr/share/agent0s/migrations/
themes/**                      ──►  agent0s             /usr/share/agent0s/themes/
shell/**                       ──►  agent0s             /usr/share/agent0s/shell/
version                        ──►  agent0s             /usr/share/agent0s/version
                                                        + /etc/skel/.local/state/agent0s/migrations/*

config/**                      ──►  agent0s-settings    /etc/skel/.config/**         (seeds new users)
                                                        /usr/share/agent0s/config/** (resync source)
etc/fastfetch/config.jsonc     ──►  agent0s-settings    /etc/fastfetch/config.jsonc
etc/xdg/kitty/kitty.conf       ──►  agent0s-settings    /etc/xdg/kitty/kitty.conf

applications/*.desktop         ──►  agent0s-settings    /etc/skel/.local/share/applications/
                                                        /usr/share/agent0s/applications/
default/applications/battlenet.desktop
                                ──►  agent0s-settings    /usr/share/agent0s/default/applications/
                                                        (installer-only launcher template)
applications/icons/*           ──►  agent0s-settings    /usr/share/icons/hicolor/{48,256,scalable}/apps/

etc/**                         ──►  agent0s-settings    /etc/**           (drop-ins we own outright)
  ├─ mkinitcpio.conf.d/{agent0s_hooks,thunderbolt_module}.conf
  ├─ limine-entry-tool.d/{agent0s-defaults,agent0s-uki}.conf
  ├─ NetworkManager/, sudoers.d/, sysctl.d/, tmpfiles.d/,
  │  profile.d/agent0s.sh, …                            (a summary — `ls etc/` for the full ~17-entry tree)
  └─ security/faillock.conf, nsswitch.conf,
     cups/cups-browsed.conf, plymouth/plymouthd.conf    /usr/share/agent0s/etc-overrides/
                                                          → /etc/* (post_install cp -f, see below)

default/limine/limine.conf     ──►  agent0s-settings    /usr/share/agent0s/default/limine/limine.conf
default/limine/default.conf    ──►  agent0s-settings    /usr/share/agent0s/default/limine/default.conf
                                                        (template; ISO substitutes @@CMDLINE@@ → /etc/default/limine)
default/snapper/root           ──►  agent0s-settings    /etc/snapper/config-templates/agent0s
                                                        (+ /usr/share/agent0s/default/snapper/root)

default/**                     ──►  agent0s-settings    /usr/share/agent0s/default/
  ├─ bash/env-bootstrap                                 /usr/share/agent0s/default/bash/env-bootstrap
  │                                                       (sourced by every shell/session entry point; see "Env bootstrap")
  ├─ bashrc                                             /usr/share/agent0s/etc-overrides/dot.bashrc
  │                                                       → /etc/skel/.bashrc (post_install cp -f)
  ├─ hypr/toggles/*.lua (flags,
  │    single-window-aspect-ratio, window-no-gaps)      /etc/skel/.local/state/agent0s/toggles/hypr/
  ├─ nautilus-python/extensions/*.py                    /etc/skel/.local/share/nautilus-python/extensions/
  ├─ tensaku/state.toml                                 /etc/skel/.local/state/tensaku/state.toml
  ├─ uwsm/env.d/10-agent0s                              /usr/share/uwsm/env.d/
  ├─ environment.d/*.conf                               /usr/lib/environment.d/
  ├─ fontconfig/conf.avail/50-agent0s.conf              /usr/share/fontconfig/conf.avail/
  │                                                       + symlink /etc/fonts/conf.d/50-agent0s.conf
  ├─ xdg-terminal-exec/*.list                           /usr/share/xdg-terminal-exec/
  ├─ applications/mimeapps.list                         /usr/share/applications/mimeapps.list
  ├─ systemd/user/*.service                             /usr/lib/systemd/user/
  ├─ systemd/user/app.slice.d/10-oomd.conf              /usr/lib/systemd/user/app.slice.d/
  ├─ systemd/system-sleep/unmount-fuse                  /usr/lib/systemd/system-sleep/
  ├─ systemd/zram-generator.conf.d/90-agent0s.conf      /usr/lib/systemd/zram-generator.conf.d/
  ├─ fonts/agent0s/agent0s.ttf                          /usr/share/fonts/agent0s/
  ├─ sddm/agent0s/                                      /usr/share/sddm/themes/agent0s/
  ├─ sddm/hyprland.lua                                  /usr/share/sddm/hyprland.lua
  ├─ wayland-sessions/agent0s.desktop                   /usr/local/share/wayland-sessions/
  └─ plymouth/                                          /usr/share/plymouth/themes/agent0s/

logo.{txt,svg}, icon.{txt,png}  ──► agent0s-settings    /usr/share/agent0s/  (resync source)
                                                        /usr/share/pixmaps/agent0s.png
                                                        /usr/share/icons/hicolor/256x256/apps/agent0s.png
                                                        /etc/skel/.config/agent0s/branding/{about,screensaver}.txt
```

The hardware-conditional `force-igpu` and `keyboard-backlight` sources also live under `default/systemd/system-sleep/`, but their setup commands publish root-owned copies only on machines that need them; they are not installed by `agent0s-settings`.

### Why `etc-overrides/` exists

Some files under `/etc/` (`.bashrc` in `/etc/skel`, `nsswitch.conf`,
`security/faillock.conf`, `cups/cups-browsed.conf`, `plymouth/plymouthd.conf`)
are owned by upstream Arch packages, so we can't install over them via pacman
without a file conflict. Instead their sources (under `etc/` in the repo;
`.bashrc` from `default/bashrc`) ship at
`/usr/share/agent0s/etc-overrides/` and the `agent0s-settings` `post_install`
/ `post_upgrade` scriptlet `cp -f`'s them into place.

Tradeoff: user edits to those files get clobbered on every `agent0s-settings`
upgrade. This is documented in the PKGBUILD.

## Locate indexing

`default/systemd/system/plocate-updatedb.service.d/10-agent0s.conf` ships through `agent0s-settings` to `/usr/lib/systemd/system/plocate-updatedb.service.d/10-agent0s.conf`. It replaces the existing service's `ExecStart` with `updatedb --prune-bind-mounts=no --add-prunepaths=/.snapshots`, keeping Btrfs subvolume mounts searchable and excluding Snapper snapshots. The upstream service retains its timer, resource limits, and sandbox; Agent0S's existing AC-power condition still applies.

`/etc/updatedb.conf` remains owned by plocate and is never rewritten by Agent0S. The command-line options override bind-mount pruning and add to the administrator's existing path exclusions. Installer and AUR package refreshes pass the same options directly because installation may run without systemd and an explicitly requested refresh should work on battery.

Arch's systemd package hook reloads units when the vendor drop-in is installed or upgraded. The settings package containing the drop-in must ship alongside the runtime package that removes the old configuration helper and migration. Pacman removes those retired files; no new state migration is needed. A running indexer finishes with its original options, and subsequent service starts use the drop-in. For an immediate local test after installing the packages, restart `plocate-updatedb.service` while connected to AC power.

## Env bootstrap (`default/bash/env-bootstrap`)

Single source of truth for `AGENT0S_PATH` and dev-link-aware `PATH`. It:

- Sources `/etc/agent0s.conf` (written by `agent0s-dev-link`, reset to the
  package path by `agent0s-dev-unlink`) if present; otherwise forces
  `AGENT0S_PATH=/usr/share/agent0s` so a stale inherited value can't survive
  an `agent0s-dev-unlink`.
- Prepends `$AGENT0S_PATH/bin` to `PATH` **only when** `AGENT0S_PATH` is
  not `/usr/share/agent0s`. On a production install the binaries are
  already on `PATH` as `/usr/bin/agent0s-*` via the `agent0s` package.
- Appends `~/.local/share/mise/shims` and `~/.local/bin` so login shells and
  the uwsm session find mise-managed tools — kept in sync with the PAM `PATH`
  line written by `install/config/ssh-command-path.sh`, which covers SSH
  commands that run no shell setup at all.

Sourced by every entry point that needs the env set:

```
/etc/profile.d/agent0s.sh                      (system login shells)
/etc/skel/.bashrc                              (interactive shells)
/usr/share/uwsm/env.d/10-agent0s               (Hyprland session via uwsm)
/usr/share/agent0s/default/bash/envs           (SSH / non-login bash)
```

Idempotent — safe to source more than once in the same shell.

`PATH` covers everything the user runs, but not `sudo`, which resolves command
names against `secure_path` from `/etc/sudoers`. So `agent0s-dev-link` also
writes `/etc/sudoers.d/agent0s-dev-path`:

```
Defaults secure_path="<checkout>/bin:/usr/local/sbin:/usr/local/bin:/usr/bin"
```

Without it, `sudo agent0s-*` fails for a command the package has not shipped
yet and silently runs the packaged copy of one it has. The drop-in is validated
with `visudo -c` before install and removed by `agent0s-dev-unlink`; unlike
`/etc/agent0s.conf`, it takes effect without a reboot.

## Runtime finalization (`agent0s-provision-user`)

Runs once per user. It does **not** copy `~/.config/**`, `~/.bashrc`,
`flags.lua`, or the nautilus extensions — `/etc/skel` already seeded those.
It only does the things `/etc/skel` can't:

- Skill symlinks into `~/.agents/skills/<name>`, `~/.claude/skills/<name>`, `~/.codex/skills/<name>`, `~/.pi/agent/skills/<name>`, `~/.gemini/config/skills/<name>` (Antigravity), `~/.hermes/skills/<name>`, and each existing `~/.hermes/profiles/*/skills/<name>` → `$AGENT0S_PATH/default/agents/skills/<name>`, looping over every skill directory there (currently `agent0s` and `diagnose-crash`) so new skills need no edit. Symlinks (not copies) so `agent0s dev link` against a dev checkout repoints them correctly. Hermes profile dirs are only linked when they already exist — provision does not create Hermes profiles.
- `xdg-user-dirs-update` (Templates/Public/Desktop folded back into `$HOME`)
  and `~/.config/gtk-3.0/bookmarks` (needs `$HOME` expansion).
- Hyprland's package-owned default input reads `XKBLAYOUT` / `XKBVARIANT`
  from `/etc/vconsole.conf`; no per-user Hyprland config rewrite is needed.
- `xdg-settings set default-web-browser chromium.desktop` and
  `xdg-mime default HEY.desktop x-scheme-handler/mailto` (XDG-aware paths).
- `agent0s-refresh-applications` (composes generated `.desktop` launchers).
- Sources `install/user/all.sh` — theme, chromium, git, xcompose, mise,
  keyring, per-user hardware quirks (asus mic/mixer, framework f13 audio, …).
- On `--first-install`, marks every shipped user migration as already applied
  for the freshly-created user.

Idempotency marker: `~/.local/state/agent0s/done/finalize-user`, managed
by `agent0s-done`.

The ISO calls it as `agent0s-provision-user --force --first-install` in the
target chroot as the install user, after `agent0s-apply-system` has finished
the root-side work. `agent0s-provision-owner` makes the same call (with
`AGENT0S_SETUP_CONTEXT=provision-owner`) when it creates the user during
deferred first-boot provisioning.

## Migrations (`agent0s-migrate`)

See [`migrations.md`](../agents/skills/migrations.md) for the full migration model, authoring
guidelines, and troubleshooting notes.

Agent0S migrations live in `migrations/*.sh` and run per-user through
`agent0s-migrate`. Completion state lives in
`~/.local/state/agent0s/migrations/`, so every user gets a chance to run every
migration. Migrations run as the user; privileged work should invoke the
appropriate helper or privilege prompt. Migrations must be idempotent;
machine-wide repairs should no-op when another user already applied them.

Each graphical user has `agent0s-migrate-notify.service`, started once per login
through `WantedBy=graphical-session.target` and ordered after that target so
notification actions can safely launch through UWSM. The `omarchy-pkgs`
PKGBUILD has shipped `agent0s-update-user-notify.service` as a symlink onto
it, so users enabled under the old unit name keep working before they reach
migration `1785095882`.
It runs `agent0s-migrate-notify` as
that user, which checks `agent0s-migrate --pending`. If this user has missing
migration state, it shows a notification that opens a terminal for
`agent0s-migrate`. The notifier never runs migrations in the background.

Login is the only trigger. Nothing watches the packaged migration directory: a
watcher cannot tell a bypassed `pacman -Syu` from the package transaction inside
a normal `agent0s update`, so it notified about migrations that `agent0s-migrate`
was already applying in the visible update terminal.

`agent0s-migrate` waits for any active pacman transaction to finish, then runs
pending migrations. It does not need `--force`; migrations happen when state
files are missing. `agent0s update` runs `agent0s-migrate` after the package
transaction in the already-visible update terminal, then runs
`agent0s-hook post-update`.

## First-run (`agent0s-provision-first-run`)

Runs once on first interactive login, after the user manager is live. It
first runs `agent0s-provision-user || true` so finalize catches up if it
never ran, then handles the steps that need a running graphical session
and/or a working user systemd instance:

- `agent0s-hook-install post-update` for the three shipped hooks
  (`install-voxtype.hook`, `setup-fingerprint.hook`, `setup-agent.hook`).
- `install/user/first-run/enable-user-units.sh` — daemon-reload, then
  `systemctl --user enable --now` the shipped user units (`bt-agent`,
  `agent0s-sleep-lock`, `agent0s-recover-internal-monitor`,
  `agent0s-migrate-notify.service`, `agent0s-fcitx5.service`,
  `agent0s-crash-watch.service`) so they run in the first session too.
  Done here, not at finalize, because
  the user manager isn't reachable from the ISO chroot; `ConditionPath*`
  in the unit files keeps services inert when they don't apply.
- `install/user/first-run/gnome-theme.sh`,
  `install/user/first-run/gtk-primary-paste.sh` — GNOME/GTK settings that
  need the dconf daemon.
- `install/user/first-run/audio-tuning.sh` — apply speaker tuning.
- `install/user/first-run/welcome.sh` — keybindings toast that greets the
  first login and opens the cheatsheet when clicked. The caller runs
  `agent0s-notification-wait` once before this and the Wi-Fi step, so both
  toasts land on a live notification server.
- `install/user/first-run/wifi.sh` — Wi-Fi/update toasts (waits detached on
  `nm-online` so the update prompt only lands once there is a connection).

The entire sequence has one idempotency marker:
`~/.local/state/agent0s/done/first-run-user`, managed by `agent0s-done`.
Completed users exit before any first-run step. On failure the marker is not
written and the sequence retries next login.

Completion markers live under `~/.local/state/agent0s/done/`. Use
`agent0s-done check <name>` to check one and `agent0s-done mark <name>` to record it.
Use `agent0s-done ensure <name>` as a conditional when the guarded work should
run only once; it records completion before returning success.
The Quattro upgrade completes graphical first-run for upgraded users and moves
the legacy finalization marker from `~/.local/state/agent0s/` into `done/`.

## Root-side install orchestration

`agent0s-apply-system` (root, in chroot) runs target-side setup at ISO
finalization. It sources:

- `install/config/all.sh` — theme links, lockout limits, lockscreen PAM,
  powerprofilesctl shebang fix, SSH command path and keepalive, docker setup,
  Snapper retention, locate index tuning, service enablement, firewall.
- `install/hardware/all.sh` via `agent0s-apply-hardware` — vendor- and
  device-specific kernel modules, udev rules, microcode, wireless regdom,
  ASUS / Framework / Intel / Apple / Lenovo quirks.
- `install/login/all.sh` — SDDM theme/session config.
- `install/post-install/all.sh` — final pacman/udev/localdb passes.

Logging goes to `/var/log/agent0s-install.log` via
`install/helpers/logging.sh`.

The package lists the ISO pacstraps live at `install/agent0s-base.packages`
and `install/agent0s-other.packages`; the ISO builder also reads them when
constructing its offline mirror.

## Explicit resync (`agent0s-reinstall-configs`)

When an existing user wants to reset to shipped defaults:

```
~/  ←  cp -af /etc/skel/.
```

Replaying `/etc/skel` over `$HOME` is exactly what `useradd -m` does for a
brand-new user, so this one copy resyncs `.bashrc`, `.config/**`,
`.local/share/applications/`, the nautilus-python extensions, hypr toggles,
branding files, and the shipped migration markers in a single pass.

Then it runs `agent0s-refresh-limine`, `agent0s-refresh-plymouth`, and the
nvim refresh. Destructive: existing user files copied from `/etc/skel` are
clobbered without backup. Fastfetch is package-owned at
`/etc/fastfetch/config.jsonc`; delete `~/.config/fastfetch/config.jsonc` to
return to the packaged default.

## Quick reference: where does X live?

| Goal | Touch |
| --- | --- |
| Default file at `~/.config/foo/` | `config/foo/` |
| `/etc/` drop-in we own outright | `etc/` |
| `/etc/` file owned by an upstream package | `etc/` (see `etc/security/faillock.conf`), then add to `etc-overrides` in `agent0s-settings` PKGBUILD + scriptlet |
| Package-owned system file (e.g. systemd user service in `/usr/lib`) | `default/`, then add the `install -Dm644` line in `agent0s-settings` PKGBUILD |
| Per-user file that's static but lives outside `~/.config` | `default/`, then add `install -Dm644 ... $pkgdir/etc/skel/...` in `agent0s-settings` PKGBUILD |
| Runtime tweak that needs `$HOME` or live system state | extend `agent0s-provision-user`, or add a per-user leaf under `install/user/` and wire into `install/user/all.sh` |
| One-time root-side setup step | `install/config/*.sh` or `install/hardware/*.sh`, wire into `install/config/all.sh` or `install/hardware/all.sh` |
| One-time fix for existing installs | `migrations/<unix-timestamp>.sh` |
| Package-owned path something else may already write | Prefer a path nothing else writes, such as a vendor drop-in under `/usr/lib`. Otherwise the `--overwrite` entry in `bin/agent0s-update-system-pkgs` has to ship a release before the file |
| User-facing `agent0s-*` command | `bin/agent0s-<group>-<verb>` — see `GROUP_DESCRIPTIONS` in `bin/agent0s` |
| New stock theme | `themes/<name>/` (+ matching templates under `default/themed/` if they need theme colors) |
| User-installed theme | `~/.config/agent0s/themes/<name>/` |
| Generated current theme/background state | `~/.local/state/agent0s/current/` |

## Kitty defaults and user overrides

Kitty loads `/etc/xdg/kitty/kitty.conf` before `~/.config/kitty/kitty.conf`. The `agent0s-settings` package owns the system file; the user template contains only the active theme include and commented examples for personal overrides. Keeping the theme include in the user file lets users remove it without changing the packaged defaults. Individual inherited keybindings can be unmapped with an empty `map <shortcut>` directive, or all inherited bindings can be cleared with `clear_all_shortcuts yes`.

The system default uses `allow_remote_control socket-only` so Agent0S can query the active terminal directory over its Unix socket while Kitty rejects remote-control requests arriving through terminal output. Changing this setting requires restarting Kitty. The migration refreshes the exact previous stock config with a backup; customized configs retain their settings and ordering, with only explicit unrestricted `yes`, `y`, or `true` remote-control settings commented out.
