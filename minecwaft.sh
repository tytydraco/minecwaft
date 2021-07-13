#!/usr/bin/env bash

log() {
  echo -e "\e[1m\e[93m * $*\e[39m\e[0m"
}

err() {
  echo -e "\e[1m\e[31m ! $*\e[39m\e[0m"
}

assert_git() {
  if ! command -v git &> /dev/null
  then
    err "git not accessible"
    exit 1
  fi
}

assert_gh() {
  if ! command -v gh &> /dev/null
  then
    err "gh not accessible"
    exit 1
  fi
}

source_config() {
  # shellcheck source=/dev/null
  source "$CONFIG_PATH"
}

append_crontab() {
  local tmpfile
  tmpfile="$(mktemp)"

  crontab -l > "$tmpfile" 2> /dev/null
  echo "$*" >> "$tmpfile"
  crontab "$tmpfile"

  rm "$tmpfile"
}

append_crontab_backup_script() {
  local cron
  local command
  local pwd

  pwd="$(pwd)"
  cron="$(crontab -l 2> /dev/null)"
  command="*/5 * * * * cd \"$pwd\" && git add . && git commit -sam \"\$(date)\" && git push"

  if [[ "$cron" == *"$pwd"* ]]
  then
    err "Entry already exists in crontab"
    exit 1
  fi

  append_crontab "$command"
  log "Added entry to crontab"

  git init

  gh repo create

  git add .
  git commit -sam "$(date)"
  git push
}

assert_git
assert_gh
append_crontab_backup_script
