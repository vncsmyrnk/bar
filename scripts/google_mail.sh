#!/usr/bin/env bash

# target: google_mail.r.15m.sh

sanitize_text() {
  printf '%s' "$1" |
    tr '\r\n\t' '   ' |
    sed -E 's/[[:space:]]+/ /g; s/\|/¦/g; s/^ //; s/ $//'
}

fail() {
  echo "Mail unavailable | color=red"
  echo "---"
  sanitize_text "$1"
  echo
  echo "---"
  echo "Refresh | refresh=true"
  exit 1
}

if ! command -v gog >/dev/null || ! command -v jq >/dev/null; then
  fail "Error: this script needs gog and jq installed"
fi

query_error=$(mktemp) ||
  fail "Error: failed to create temporary storage for gog errors"
trap 'rm -f "$query_error"' EXIT

if ! mail_json=$(
  gog gmail search "in:inbox is:unread (category:primary OR category:primary)" \
    --max=10 \
    --count \
    --readonly \
    --no-input \
    --json \
    2>"$query_error"
); then
  query_message=$(cat "$query_error")
  fail "Error: ${query_message:-gog Gmail query failed}"
fi
if [[ -s "$query_error" ]]; then
  fail "Error: $(cat "$query_error")"
fi

if ! jq -e '
  type == "object"
  and (.threads | type == "array")
  and (.threads | length <= 10)
  and all(.threads[];
    type == "object"
    and (.id | type == "string")
    and (.id | test("^[0-9A-Fa-f]+$"))
    and ((has("subject") | not) or (.subject | type == "string"))
  )
  and (
    (has("totalMatches") and (has("totalMatchesAtLeast") | not))
    or ((has("totalMatches") | not) and has("totalMatchesAtLeast"))
  )
  and (
    (.totalMatches // .totalMatchesAtLeast) as $count
    | ($count | type == "number")
      and ($count >= 0)
      and ($count == ($count | floor))
      and ($count >= (.threads | length))
  )
' >/dev/null 2>&1 <<<"$mail_json"; then
  fail "Error: gog returned malformed mail data"
fi

if ! rendered=$(
  jq -r '
    def clean_text:
      (. // "")
      | tostring
      | gsub("[\r\n\t]+"; " ")
      | gsub("[|]"; "¦")
      | gsub("  +"; " ")
      | gsub("^ +| +$"; "")
      | sub("^--"; "—")
      | if length == 0 then "(no subject)" else . end;

    def thread_line:
      (.subject | clean_text)
      + " | href=https://mail.google.com/mail/u/0/#inbox/"
      + .id
      + " useMarkup=false ansi=false unescape=false emojize=false";

    (.totalMatches // .totalMatchesAtLeast) as $count
    | (
        if has("totalMatches") then
          "\($count)"
        else
          "\($count)+"
        end
      ) as $menu
    | [$menu, "---"]
      + (
          if (.threads | length) == 0 then
            ["No unread emails"]
          else
            (.threads | map(thread_line))
          end
        )
      + ["---", "Refresh | refresh=true"]
    | .[]
  ' <<<"$mail_json"
); then
  fail "Error: failed to format unread mail"
fi

printf '📬 %s\n' "$rendered"
