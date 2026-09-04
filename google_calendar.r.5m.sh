#!/usr/bin/env bash

CALENDARS="${CALENDARS:-}"
NOW_EPOCH="${NOW_EPOCH:-$(date +%s)}"

sanitize_text() {
  printf '%s' "$1" |
    tr '\r\n\t' '   ' |
    sed -E 's/[[:space:]]+/ /g; s/\|/¦/g; s/^ //; s/ $//'
}

fail() {
  echo "Calendar unavailable | color=red"
  echo "---"
  sanitize_text "$1"
  echo
  echo "---"
  echo "Refresh | refresh=true"
  exit 1
}

if ! command -v gog >/dev/null && command -v jq >/dev/null; then
  fail "Error: this script needs gog and jq installed"
fi

if ! [[ "$NOW_EPOCH" =~ ^[0-9]+$ ]]; then
  fail "Error: NOW_EPOCH must be a Unix timestamp"
fi

today=$(date -d "@$NOW_EPOCH" +%Y-%m-%d) ||
  fail "Error: failed to determine the current date"
tomorrow=$(date -d "$today + 1 day" +%Y-%m-%dT%H:%M:%S) ||
  fail "Error: failed to determine tomorrow"
weekday=$(date -d "@$NOW_EPOCH" +%u) ||
  fail "Error: failed to determine the current weekday"
week_end_epoch=$(date -d "$today + $((8 - 10#$weekday)) days" +%s) ||
  fail "Error: failed to determine the end of the week"
from=$(date --iso-8601=seconds -d "@$NOW_EPOCH") ||
  fail "Error: failed to format the query start"
to=$(date --iso-8601=seconds -d "@$week_end_epoch") ||
  fail "Error: failed to format the query end"
now_local=$(date -d "@$NOW_EPOCH" +%Y-%m-%dT%H:%M:%S) ||
  fail "Error: failed to format the current time"

calendar_args=(--all)
if [[ -n "$CALENDARS" ]]; then
  calendar_args=("--calendars=$CALENDARS")
fi

query_error=$(mktemp) ||
  fail "Error: failed to create temporary storage for gog errors"
trap 'rm -f "$query_error"' EXIT

if ! events_json=$(
  gog calendar events \
    "${calendar_args[@]}" \
    --from="$from" \
    --to="$to" \
    --max=250 \
    --all-pages \
    --sort=start \
    --timezone=local \
    --readonly \
    --json \
    --results-only \
    --fields='items(id,summary,start,end,status,htmlLink),nextPageToken' \
    2>"$query_error"
); then
  query_message=$(cat "$query_error")
  fail "Error: ${query_message:-gog calendar query failed}"
fi
if [[ -s "$query_error" ]]; then
  fail "Error: $(cat "$query_error")"
fi

if ! jq -e '
  type == "array"
  and all(.[];
    type == "object"
    and (.start | type == "object")
    and (.end | type == "object")
    and (
      (
        (.start.dateTime | type == "string")
        and (.end.dateTime | type == "string")
        and (.startLocal | type == "string")
        and (.endLocal | type == "string")
      )
      or
      (
        (.start.date | type == "string")
        and (.end.date | type == "string")
      )
    )
  )
' >/dev/null 2>&1 <<<"$events_json"; then
  fail "Error: gog returned malformed event data"
fi

if ! rendered=$(
  jq -r \
    --arg now "$now_local" \
    --arg today "$today" \
    --arg tomorrow "$tomorrow" '
    def clean_text:
      (. // "(no title)")
      | tostring
      | gsub("[\r\n\t]+"; " ")
      | gsub("[|]"; "¦")
      | gsub("  +"; " ")
      | gsub("^ +| +$"; "");

    def clean_link:
      (. // "")
      | tostring
      | gsub("[\r\n\t |]"; "");

    def day_label:
      strptime("%Y-%m-%d")
      | mktime
      | strftime("%A, %b %d");

    def event_line:
      (
        if .all_day then
          "All day"
        elif .start <= $now then
          "Now-\(.end[11:16])"
        else
          "\(.start[11:16])-\(.end[11:16])"
        end
      )
      + " " + .summary
      + (if .link == "" then "" else " | href=" + .link end);

    map(
      select((.status // "confirmed") != "cancelled")
      | if .start.date? != null then
          {
            all_day: true,
            start: .start.date,
            end: .end.date,
            summary: (.summary | clean_text),
            link: (.htmlLink | clean_link)
          }
        else
          {
            all_day: false,
            start: .startLocal[0:19],
            end: .endLocal[0:19],
            summary: (.summary | clean_text),
            link: (.htmlLink | clean_link)
          }
        end
    )
    | map(select(if .all_day then .end > $today else .end > $now end))
    | sort_by(.start)
    | . as $events
    | (
        $events
        | map(select(
            if .all_day then
              .start < $tomorrow and .end > $today
            else
              .start < $tomorrow and .end > $now
            end
          ))
        | length
      ) as $today_count
    | ($events | map(select(.all_day | not)) | .[0]) as $next
    | (
        if $next == null then
          "No timed - \($today_count) today"
        elif $next.start <= $now then
          "Now-\($next.end[11:16]) \($next.summary) - \($today_count) today"
        else
          "\($next.start[11:16]) \($next.summary) - \($today_count) today"
        end
      ) as $menu
    | (
        $events
        | map(. + {
            display_day: (
              if (.all_day and .start <= $today)
                or ((.all_day | not) and .start <= $now)
              then $today
              else .start[0:10]
              end
            )
          })
      ) as $display_events
    | [$menu, "---"]
      + (
          if ($display_events | length) == 0 then
            ["No remaining events"]
          else
            reduce ($display_events | group_by(.display_day)[]) as $group
              ([];
                . + [
                  (($group[0].display_day | day_label) + " | color=gray")
                ]
                + ($group | map(event_line))
              )
          end
        )
      + ["---", "Refresh | refresh=true"]
    | .[]
  ' <<<"$events_json"
); then
  fail "Error: failed to format calendar events"
fi

printf '📅 %s\n' "$rendered"
