echo "Move current Agent0S theme state to ~/.local/state"

legacy_current_dir="$HOME/.config/agent0s/current"
current_state_dir="$HOME/.local/state/agent0s/current"

mkdir -p "$HOME/.local/state/agent0s"

if [[ -e $legacy_current_dir || -L $legacy_current_dir ]]; then
  if [[ ! -e $current_state_dir && ! -L $current_state_dir ]]; then
    mv "$legacy_current_dir" "$current_state_dir"
  else
    if [[ -d $legacy_current_dir && -d $current_state_dir ]]; then
      cp -an "$legacy_current_dir/." "$current_state_dir/" 2>/dev/null || true
    fi
    rm -rf "$legacy_current_dir"
  fi
fi

replace_literal_in_file() {
  local file="$1"
  local old="$2"
  local new="$3"
  local tmp

  grep -Fq -- "$old" "$file" || return 0

  tmp=$(mktemp)
  OLD="$old" NEW="$new" awk '
    BEGIN {
      old = ENVIRON["OLD"]
      new = ENVIRON["NEW"]
    }
    {
      while ((pos = index($0, old)) > 0) {
        $0 = substr($0, 1, pos - 1) new substr($0, pos + length(old))
      }
      print
    }
  ' "$file" >"$tmp"
  cat "$tmp" >"$file"
  rm -f "$tmp"
}

replace_current_path() {
  local file="$1"

  [[ -f $file ]] || return 0

  replace_literal_in_file "$file" "$HOME/.config/agent0s/current" "$HOME/.local/state/agent0s/current"
  replace_literal_in_file "$file" "~/.config/agent0s/current" "~/.local/state/agent0s/current"
  replace_literal_in_file "$file" "../agent0s/current" "../../.local/state/agent0s/current"
}

ensure_hyprland_state_path() {
  local file="$HOME/.config/hypr/hyprland.lua"
  local tmp

  [[ -f $file ]] || return 0
  grep -Fq '/.local/state/?.lua;' "$file" && return 0
  grep -Fq '/default/hypr/bootstrap.lua' "$file" && return 0
  grep -Fq '  .. "/.config/?.lua;"' "$file" || return 0

  tmp=$(mktemp)
  awk '
    !inserted && $0 == "  .. \"/.config/?.lua;\"" {
      print "  .. \"/.local/state/?.lua;\""
      print "  .. os.getenv(\"HOME\")"
      inserted = 1
    }
    { print }
  ' "$file" >"$tmp"
  cat "$tmp" >"$file"
  rm -f "$tmp"
}

for file in \
  "$HOME/.config/alacritty/alacritty.toml" \
  "$HOME/.config/foot/foot.ini" \
  "$HOME/.config/ghostty/config" \
  "$HOME/.config/hypr/hyprland.conf" \
  "$HOME/.config/hypr/hyprland.lua" \
  "$HOME/.config/hyprland-preview-share-picker/config.yaml" \
  "$HOME/.config/kitty/kitty.conf"; do
  replace_current_path "$file"
done

ensure_hyprland_state_path

relink_current_symlink() {
  local link="$1"
  local target suffix

  [[ -L $link ]] || return 0
  target=$(readlink "$link") || return 0

  case "$target" in
    "$legacy_current_dir"/*)
      suffix=${target#"$legacy_current_dir"/}
      ln -sfn "$current_state_dir/$suffix" "$link"
      ;;
    "~/.config/agent0s/current/"*)
      # The filesystem never expands a literal ~ in a symlink target, so keep
      # $HOME out of the quoted string and let the shell expand it instead.
      suffix=${target#"~/.config/agent0s/current/"}
      ln -sfn "$current_state_dir/$suffix" "$link"
      ;;
  esac
}

for link in \
  "$HOME/.config/btop/themes/current.theme" \
  "$HOME/.config/helix/themes/agent0s.toml" \
  "$HOME/.vscode/extensions/agent0s-theme/themes/agent0s-color-theme.json" \
  "$HOME/.vscode-insiders/extensions/agent0s-theme/themes/agent0s-color-theme.json" \
  "$HOME/.vscode-oss/extensions/agent0s-theme/themes/agent0s-color-theme.json" \
  "$HOME/.cursor/extensions/agent0s-theme/themes/agent0s-color-theme.json"; do
  relink_current_symlink "$link"
done
