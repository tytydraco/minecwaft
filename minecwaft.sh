#!/usr/bin/env bash

CRON_PATTERN="*/10 * * * *"

log() {
  echo -e "\e[1m\e[93m * $*\e[39m\e[0m"
}

err() {
  echo -e "\e[1m\e[31m ! $*\e[39m\e[0m"
}

usage() {
  echo "Crontab auto-backup helper using git
Usage: $0 [-h] [-a] [-r] [-p PATTERN] [PATH]
  -h            Show this screen
  -a            Add the current directory as a backup entry
  -r            Remove the current directory as a backup entry
  -p            Specify a custom cron pattern (default: $CRON_PATTERN)"
}

assert_deps() {
  for dep in git gh mktemp crontab sed
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
  local command
  local pwd
  local tmpfile

  pwd="$(pwd)"
  command="$CRON_PATTERN minecwaft '$pwd'"

  if crontab -l 2> /dev/null | grep -q "$pwd"
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
  git branch -m main
  git add .
  git commit -sam "$(date)"

  log "Select the option to push an existing repository!"
  gh repo create

  git push -u origin main

  log "Setup complete for: $pwd"
}

remove_crontab_backup_script() {
  local command
  local pwd
  local tmpfile

  pwd="$(pwd)"

  if ! crontab -l 2> /dev/null | grep -q "$pwd"
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

update() {
  local path
  path="$1"

  if ! crontab -l 2> /dev/null | grep -q "$pwd"
  then
    err "Entry does not exist in crontab"
    exit 1
  fi

  if ! cd "$path"
  then
    err "Failed to change directories to $path"
    exit 1
  fi

  git add .
  git commit -sam "$(date)"
  git push -u origin main

  log "Pushed successfully"
}

parse_options() {
  while getopts ":harp:" opt
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
    p)
      CRON_PATTERN="$OPTARG"
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

update "${1:-.}"
