default:
  just --list

shellcheck:
  shellcheck scripts/*

lint:
  shfmt -ln bash -d -i 2 scripts/*

build:
  #!/usr/bin/env bash
  mkdir -p ./build
  for s in ./scripts/*; do
    if ! target=$(grep -oP '^# target: \K([a-zA-Z0-9-_.]+)' "$s"); then
      echo "using own script file name for $s" >&2
      target=$(basename "$s")
    fi
    cp "$s" "./build/$target"
  done

clean:
  rm -rf ./build

install:
  mkdir -p "{{home_dir()}}/.config/argos"
  stow -t "{{home_dir()}}/.config/argos" build

uninstall:
  stow -D -t "{{home_dir()}}/.config/argos" build
