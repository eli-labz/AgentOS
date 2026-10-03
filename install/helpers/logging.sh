agent0s_log_to_stdout() {
  [[ ${AGENT0S_LOG_TO_STDOUT:-} == "1" || -z ${AGENT0S_INSTALL_LOG_FILE:-} ]]
}

agent0s_log_line() {
  if agent0s_log_to_stdout; then
    echo "$1"
  else
    echo "$1" >>"$AGENT0S_INSTALL_LOG_FILE"
  fi
}

start_install_log() {
  if ! agent0s_log_to_stdout; then
    mkdir -p "$(dirname "$AGENT0S_INSTALL_LOG_FILE")"
    touch "$AGENT0S_INSTALL_LOG_FILE"
    chmod 666 "$AGENT0S_INSTALL_LOG_FILE" 2>/dev/null || true
  fi

  export AGENT0S_START_TIME="${AGENT0S_START_TIME:-$(date '+%Y-%m-%d %H:%M:%S')}"
  export AGENT0S_START_EPOCH="${AGENT0S_START_EPOCH:-$(date +%s)}"

  agent0s_log_line "=== Agent0S Setup Started: $AGENT0S_START_TIME ==="
}

stop_install_log() {
  local end_time end_epoch duration mins secs
  end_time=$(date '+%Y-%m-%d %H:%M:%S')
  end_epoch=$(date +%s)

  agent0s_log_line "=== Agent0S Setup Completed: $end_time ==="

  if [[ -n ${AGENT0S_START_EPOCH:-} ]]; then
    duration=$((end_epoch - AGENT0S_START_EPOCH))
    mins=$((duration / 60))
    secs=$((duration % 60))
    agent0s_log_line "Agent0S setup: ${mins}m ${secs}s"
  fi
}

run_logged() {
  local script="$1"
  local exit_code errexit_was_set=0

  agent0s_log_line "[$(date '+%Y-%m-%d %H:%M:%S')] Starting: $script"

  case $- in
    *e*)
      errexit_was_set=1
      set +e
      ;;
  esac

  local runner=(bash -eE)
  if [[ ${AGENT0S_INSTALL_DEBUG:-} == "1" ]]; then
    runner=(bash -x -eE)
  fi

  if agent0s_log_to_stdout; then
    PS4='+ ${BASH_SOURCE[0]##*/}:${LINENO}:${FUNCNAME[0]:-main}: ' \
      "${runner[@]}" -c 'source "$1"' bash "$script" </dev/null 2>&1
  else
    PS4='+ ${BASH_SOURCE[0]##*/}:${LINENO}:${FUNCNAME[0]:-main}: ' \
      "${runner[@]}" -c 'source "$1"' bash "$script" </dev/null >>"$AGENT0S_INSTALL_LOG_FILE" 2>&1
  fi

  exit_code=$?
  (( errexit_was_set )) && set -e

  if (( exit_code == 0 )); then
    agent0s_log_line "[$(date '+%Y-%m-%d %H:%M:%S')] Completed: $script"
  else
    agent0s_log_line "[$(date '+%Y-%m-%d %H:%M:%S')] Failed: $script (exit code: $exit_code)"
  fi

  return $exit_code
}
