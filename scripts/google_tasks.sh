#!/usr/bin/env bash

# target: google_tasks.r.15m.sh

TASK_LISTS="${TASK_LISTS:-}"
NOW_EPOCH="${NOW_EPOCH:-$(date +%s)}"

sanitize_text() {
  printf '%s' "$1" |
    tr '\r\n\t' '   ' |
    sed -E 's/[[:space:]]+/ /g; s/\|/¦/g; s/^ //; s/ $//'
}

fail() {
  echo "Tasks unavailable | color=red"
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
weekday=$(date -d "@$NOW_EPOCH" +%u) ||
  fail "Error: failed to determine the current weekday"
week_end=$(date -d "$today + $((7 - 10#$weekday)) days" +%Y-%m-%d) ||
  fail "Error: failed to determine the end of the week"

list_error=$(mktemp) ||
  fail "Error: failed to create temporary storage for gog errors"
task_error=$(mktemp) || {
  rm -f "$list_error"
  fail "Error: failed to create temporary storage for gog errors"
}
task_arrays=$(mktemp) || {
  rm -f "$list_error" "$task_error"
  fail "Error: failed to create temporary storage for task data"
}
trap 'rm -f "$list_error" "$task_error" "$task_arrays"' EXIT

if ! lists_json=$(
  gog tasks lists list \
    --all \
    --readonly \
    --no-input \
    --json \
    --results-only \
    2>"$list_error"
); then
  list_message=$(cat "$list_error")
  fail "Error: ${list_message:-gog task-list query failed}"
fi
if [[ -s "$list_error" ]]; then
  fail "Error: $(cat "$list_error")"
fi

if ! jq -e '
  type == "array"
  and all(.[];
    type == "object"
    and (.id | type == "string")
    and (.id | length > 0)
    and (.title | type == "string")
  )
' >/dev/null 2>&1 <<<"$lists_json"; then
  fail "Error: gog returned malformed task-list data"
fi

if [[ -z "$TASK_LISTS" ]]; then
  selected_lists_json=$lists_json
else
  if ! selected_lists_json=$(
    jq -ce --arg ids "$TASK_LISTS" '
      . as $lists
      | ($ids | split(",") | map(gsub("^\\s+|\\s+$"; ""))) as $wanted
      | if any($wanted[]; length == 0)
          or (($wanted | unique | length) != ($wanted | length))
        then
          error("invalid TASK_LISTS")
        elif (($wanted - ($lists | map(.id))) | length) > 0 then
          error("unknown TASK_LISTS")
        else
          [$wanted[] as $id | $lists[] | select(.id == $id)]
        end
    ' <<<"$lists_json" 2>/dev/null
  ); then
    fail "Error: TASK_LISTS contains an unknown task-list ID or invalid list"
  fi
fi

: >"$task_arrays"
while IFS= read -r task_list; do
  list_id=$(jq -r '.id' <<<"$task_list")
  list_title=$(jq -r '.title' <<<"$task_list")
  : >"$task_error"

  if ! list_tasks=$(
    gog tasks list "$list_id" \
      --all \
      --show-assigned \
      --readonly \
      --no-input \
      --json \
      --results-only \
      2>"$task_error"
  ); then
    task_message=$(cat "$task_error")
    fail "Error: ${task_message:-gog task query failed for $list_title}"
  fi
  if [[ -s "$task_error" ]]; then
    fail "Error: $(cat "$task_error")"
  fi

  if [[ "$list_tasks" == "null" ]]; then
    list_tasks='[]'
  fi

  if ! jq -e '
    type == "array"
    and all(.[];
      type == "object"
      and (.id | type == "string")
      and ((has("title") | not) or (.title | type == "string"))
      and ((has("status") | not) or (.status | type == "string"))
      and ((has("deleted") | not) or (.deleted | type == "boolean"))
      and ((has("hidden") | not) or (.hidden | type == "boolean"))
      and (
        (has("due") | not)
        or (
          (.due | type == "string")
          and (.due | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T"))
        )
      )
      and (
        (has("webViewLink") | not)
        or (.webViewLink | type == "string")
      )
    )
  ' >/dev/null 2>&1 <<<"$list_tasks"; then
    fail "Error: gog returned malformed task data for $list_title"
  fi

  jq -c \
    --arg list_id "$list_id" \
    --arg list_title "$list_title" '
    [
      .[]
      | select((.status // "needsAction") == "needsAction")
      | select((.deleted // false) | not)
      | select((.hidden // false) | not)
      | . + {
          taskListId: $list_id,
          taskListTitle: $list_title
        }
    ]
  ' <<<"$list_tasks" >>"$task_arrays" ||
    fail "Error: failed to aggregate tasks for $list_title"
done < <(jq -c '.[]' <<<"$selected_lists_json")

tasks_json=$(jq -sc 'add // []' "$task_arrays") ||
  fail "Error: failed to aggregate task data"

if ! rendered=$(
  jq -r \
    --arg today "$today" \
    --arg week_end "$week_end" '
    def clean_text:
      (. // "(no title)")
      | tostring
      | gsub("[\r\n\t]+"; " ")
      | gsub("[|]"; "¦")
      | gsub("  +"; " ")
      | gsub("^ +| +$"; "");

    def clean_link:
      (
        (. // "")
        | tostring
        | gsub("[\r\n\t |]"; "")
      ) as $link
      | if ($link | startswith("https://")) then $link else "" end;

    def day_label:
      strptime("%Y-%m-%d")
      | mktime
      | strftime("%A, %b %d");

    def task_line:
      .title + " [" + .list_title + "]"
      + (if .link == "" then "" else " | href=" + .link end);

    map({
      title: (.title | clean_text),
      list_title: (.taskListTitle | clean_text),
      due_date: (if .due? == null then null else .due[0:10] end),
      link: (.webViewLink | clean_link)
    })
    | sort_by(.due_date // "9999-99-99", .title, .list_title)
    | . as $tasks
    | ($tasks | length) as $total
    | ([$tasks[] | select(.due_date != null and .due_date < $today)] | length) as $overdue
    | ($total - $overdue) as $pending
    | (
        if $overdue == 0 then
          "\($pending)"
        else
          "\($pending) (\($overdue))"
        end
      ) as $title
    | (
        [
          {
            label: "Overdue",
            tasks: [$tasks[] | select(.due_date != null and .due_date < $today)]
          },
          {
            label: "Today",
            tasks: [$tasks[] | select(.due_date == $today)]
          }
        ]
        + (
            [
              $tasks[]
              | select(
                  .due_date != null
                  and .due_date > $today
                )
            ]
            | group_by(.due_date)
            | map({
                label: (.[0].due_date | day_label),
                tasks: .
              })
          )
        + [
            {
              label: "No date",
              tasks: [$tasks[] | select(.due_date == null)]
            }
          ]
        | map(select(.tasks | length > 0))
      ) as $sections
    | [$title, "---"]
      + (
          if $total == 0 then
            ["No pending tasks"]
          elif ($sections | length) == 0 then
            ["No tasks due this week"]
          else
            reduce $sections[] as $section
              ([];
                . + [($section.label + " | color=gray")]
                + ($section.tasks | map(task_line))
              )
          end
        )
      + ["---", "Refresh | refresh=true"]
    | .[]
  ' <<<"$tasks_json"
); then
  fail "Error: failed to format tasks"
fi

printf '📋 %s\n' "$rendered"
