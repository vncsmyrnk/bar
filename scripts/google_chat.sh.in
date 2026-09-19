#!/usr/bin/env bash

# target: google_chat.r.15m.sh

sanitize_text() {
  printf '%s' "$1" |
    tr '\r\n\t' '   ' |
    sed -E 's/[[:space:]]+/ /g; s/\|/¦/g; s/^ //; s/ $//; s/^--/—/'
}

fail() {
  echo "Chat unavailable | color=red"
  echo "---"
  printf '%s | useMarkup=false ansi=false unescape=false emojize=false\n' \
    "$(sanitize_text "$1")"
  echo "---"
  echo "Refresh | refresh=true"
  exit 1
}

if ! command -v gog >/dev/null || ! command -v jq >/dev/null; then
  fail "Error: this script needs gog and jq installed"
fi

search_error=$(mktemp) ||
  fail "Error: failed to create temporary storage for gog errors"
space_error=$(mktemp) || {
  rm -f "$search_error"
  fail "Error: failed to create temporary storage for gog errors"
}
search_data=$(mktemp) || {
  rm -f "$search_error" "$space_error"
  fail "Error: failed to create temporary storage for unread messages"
}
space_data=$(mktemp) || {
  rm -f "$search_error" "$space_error" "$search_data"
  fail "Error: failed to create temporary storage for Chat spaces"
}
trap 'rm -f "$search_error" "$space_error" "$search_data" "$space_data"' EXIT

if ! gog chat messages search 'is_unread()' \
  --max=100 \
  --order='create_time desc' \
  --view=full \
  --readonly \
  --no-input \
  --json \
  >"$search_data" 2>"$search_error"; then
  search_message=$(cat "$search_error")
  fail "Error: ${search_message:-gog Chat unread-message query failed}"
fi
if [[ -s "$search_error" ]]; then
  fail "Error: $(cat "$search_error")"
fi

if ! jq -e '
  type == "object"
  and (.results | type == "array")
  and (.results | length <= 100)
  and (.nextPageToken | type == "string")
  and all(.results[];
    . as $result
    | type == "object"
      and (.resource | type == "string")
      and (.resource | test("^spaces/[A-Za-z0-9_-]+/messages/[A-Za-z0-9_.-]+$"))
      and (.space | type == "string")
      and (.space | test("^spaces/[A-Za-z0-9_-]+$"))
      and ($result.resource | startswith($result.space + "/messages/"))
      and (
        (has("text") | not)
        or (.text == null)
        or (.text | type == "string")
      )
      and (.createTime | type == "string")
      and (.createTime | length > 0)
    )
' "$search_data" >/dev/null 2>&1; then
  fail "Error: gog returned malformed unread-message data"
fi

unread_count=$(jq -r '.results | length' "$search_data") ||
  fail "Error: failed to count unread messages"

if ((unread_count > 0)); then
  if ! gog chat spaces list \
    --all \
    --readonly \
    --no-input \
    --json \
    >"$space_data" 2>"$space_error"; then
    space_message=$(cat "$space_error")
    fail "Error: ${space_message:-gog Chat space query failed}"
  fi
  if [[ -s "$space_error" ]]; then
    fail "Error: $(cat "$space_error")"
  fi

  if ! jq -e '
    type == "object"
    and (.spaces | type == "array")
    and (.nextPageToken | type == "string")
    and (.nextPageToken | length == 0)
    and ((.spaces | map(.resource) | unique | length) == (.spaces | length))
    and all(.spaces[];
      type == "object"
      and (.resource | type == "string")
      and (.resource | test("^spaces/[A-Za-z0-9_-]+$"))
      and (.uri | type == "string")
      and (.uri | test("^https://chat\\.google\\.com/[^[:space:]|]+$"))
    )
  ' "$space_data" >/dev/null 2>&1; then
    fail "Error: gog returned malformed space data"
  fi

  if ! jq -e \
    --slurpfile space_data "$space_data" '
      ($space_data[0].spaces | map({key: .resource, value: .uri}) | from_entries) as $links
      | all(.results[0:10][]; ($links[.space]? | type) == "string")
    ' "$search_data" >/dev/null 2>&1; then
    fail "Error: gog returned incomplete space data"
  fi
else
  printf '%s\n' '{"spaces":[]}' >"$space_data"
fi

if ! rendered=$(
  jq -r \
    --slurpfile space_data "$space_data" '
    def clean_text:
      (. // "")
      | tostring
      | gsub("[\r\n\t]+"; " ")
      | gsub("[|]"; "¦")
      | gsub("  +"; " ")
      | gsub("^ +| +$"; "")
      | sub("^--"; "—")
      | if length == 0 then "(no text)" else . end;

    ($space_data[0].spaces | map({key: .resource, value: .uri}) | from_entries) as $links
    | (.results | length) as $count
    | (
        if ((.nextPageToken // "") | length) > 0 then
          "\($count)+"
        else
          "\($count)"
        end
      ) as $menu
    | [$menu, "---"]
      + (
          if $count == 0 then
            ["No unread messages"]
          else
            [
              .results[0:10][]
              | (.text | clean_text)
                + " | href=" + $links[.space]
                + " useMarkup=false ansi=false unescape=false emojize=false"
            ]
          end
        )
      + ["---", "Refresh | refresh=true"]
    | .[]
  ' "$search_data"
); then
  fail "Error: failed to format unread Chat messages"
fi

printf '💬 %s\n' "$rendered"
