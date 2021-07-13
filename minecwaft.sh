#!/usr/bin/env bash

MINUTES=10

log() {
  echo -e "\e[1m\e[93m * $*\e[39m\e[0m"
}

err() {
  echo -e "\e[1m\e[31m ! $*\e[39m\e[0m"
}

assert_deps() {
  for dep in git gh mktemp
  do
    if ! command -v "$dep" &> /dev/null
    then
      err "$dep not accessible"
      exit 1
    fi
  done
}

source_config() {
  # shellcheck source=/dev/null
  source "$CONFIG_PATH"
}

append_crontab_backup_script() {
  local cron
  local command
  local pwd
  local tmpfile

  pwd="$(pwd)"
  cron="$(crontab -l 2> /dev/null)"
  command="*/$MINUTES * * * * cd \"$pwd\" && git add . && git commit -sam \"\$(date)\"; git push"

  if [[ "$cron" == *"$pwd"* ]]
  then
    err "Entry already exists in crontab"
    exit 1
  fi

  tmpfile="$(mktemp)"

  crontab -l > "$tmpfile" 2> /dev/null
  echo "$command" >> "$tmpfile"
  crontab "$tmpfile"

  rm "$tmpfile"

  log "Added entry to crontab"

  git init

  gh repo create

  git add .
  git commit -sam "$(date)"
  git branch -m main
  git push -u origin main

  log "Setup complete for: $pwd"
}

remove_crontab_backup_script() {
  local cron
  local command
  local pwd
  local tmpfile

  pwd="$(pwd)"
  cron="$(crontab -l 2> /dev/null)"

  if [[ "$cron" != *"\"$pwd\""* ]]
  then
    err "Entry does not exist in crontab"
    exit 1
  fi

  tmpfile="$(mktemp)"

  crontab -l > "$tmpfile" 2> /dev/null
  sed -i "\|$pwd|d" "$tmpfile"
  crontab "$tmpfile"

  rm "$tmpfile"

  log "Removed entry for: $pwd"
}

usage() {
  echo "Minecraft world crontab auto-backup creator using git
Usage: $0 [-h] [-a] [-r] [-m MINUTES]
  -h            Show this screen
  -a            Add the current directory as a backup entry
  -r            Remove the current directory as a backup entry
  -m            Specify time between backups in minutes [1-59] (default: $MINUTES)"
}

parse_options() {
  while getopts ":hard:" opt
  do
    case "$opt" in
    h)
      usage
      exit 0
      ;;
    a)
      append_crontab_backup_script
      exit 0
      ;;
    r)
      remove_crontab_backup_script
      exit 0
      ;;
    d)
      MINUTES="$OPTARG"
      ;;
    *)
      usage
      exit 1
      ;;
    esac
  done
}

assert_deps
parse_options "$@"
