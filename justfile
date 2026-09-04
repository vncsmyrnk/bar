default:
  just --list

shellcheck:
  shellcheck *.sh

lint:
  shfmt -ln bash -d -i 2 *.sh

config:
  mkdir -p "{{home_dir()}}/.config/argos"
  stow -t "{{home_dir()}}/.config/argos" .

unset-config:
  stow -D -t "{{home_dir()}}/.config/argos" .
