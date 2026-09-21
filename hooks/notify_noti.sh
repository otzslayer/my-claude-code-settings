#!/usr/bin/env bash
input=$(cat)
cwd=$(jq -r '.cwd // empty' <<<"$input")

# Dayflow처럼 임시 디렉터리에서 실행된 세션은 알림을 보내지 않음
case "$cwd" in
  /var/folders/*|/private/var/folders/*) exit 0 ;;
  "$HOME/Library/Application Support/Dayflow/"*) exit 0 ;;
esac

printf '%s' "$input" | grrr hook notify --appId Claude --title "Claude Code" --sound Ping
