build_target := "build"
script_forwarded_env_allowlist_regexp := "^TAB_MAIL_NO_PRIMARY_FILTER"

default:
  just --list

shellcheck:
  shellcheck scripts/*

lint:
  shfmt -ln bash -d -i 2 scripts/*

build:
  #!/usr/bin/env bash
  mkdir -p "{{build_target}}"
  for s in ./scripts/*; do
    if ! target=$(grep -oP '^# target: \K([a-zA-Z0-9-_.]+)' "$s"); then
      echo "using own script file name for $s" >&2
      target=$(basename "$s")
    fi
    cat <<EOF >  "{{build_target}}/$target"
  #!/usr/bin/env bash
  $(env | grep -i '{{script_forwarded_env_allowlist_regexp}}' | xargs -I{} echo export {})
  trap 'rm -f \$script' EXIT
  script=\$(mktemp)
  cat <<'EOFF' >\$script
  $(cat $s)
  EOFF
  chmod +x \$script
  exec \$script "$@"
  EOF
    chmod u+x "{{build_target}}/$target"
  done

build-for-workspaces:
  TAB_MAIL_NO_PRIMARY_FILTER=1 just build

clean:
  rm -rf "{{build_target}}"

install:
  mkdir -p "{{home_dir()}}/.config/argos"
  stow -t "{{home_dir()}}/.config/argos" build

uninstall:
  stow -D -t "{{home_dir()}}/.config/argos" build
