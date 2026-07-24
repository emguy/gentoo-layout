#!/usr/bin/env bash

set -e

this_dir=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

included=()
included+=("/etc/modprobe.d/nvidia.conf")
included+=("$HOME/.config/dconf/")
#included+=("$HOME/.config/fcitx5/")
included+=("$HOME/.config/foot/")
included+=("$HOME/.config/gtk-3.0/")
included+=("$HOME/.config/gtk-4.0/")
included+=("$HOME/.config/i3status-rust/")
included+=("$HOME/.config/lazygit/")
included+=("$HOME/.config/opencode/opencode.json")
included+=("$HOME/.config/qmk/")
included+=("$HOME/.config/sway/")
included+=("$HOME/.config/systemd/")
included+=("$HOME/.gitconfig")
included+=("$HOME/.zshrc")
included+=("$HOME/.zprofile")
included+=("$HOME/.tmux.conf")
included+=("/usr/src/linux/.config")
included+=("/etc/fstab")
included+=("/etc/systemd/")
included+=("/etc/udev/rules.d/")
included+=("/etc/portage/")
included+=("/var/lib/portage/world")

for item in "${included[@]}"; do
  if [[ "${item}" =~ ^/home/.* ]]; then
    target_path="${item#/*/*/}"
    target_path="${target_path#.}" # remove dot
    target_path="home/${target_path%/}"
  else
    target_path="${item#/}"
  fi

  if [ -d "${item}" ]; then
    rm -rf "${this_dir}/${target_path}"
    mkdir -p "${this_dir}/${target_path}"
    rsync -a --no-links --verbose "${item}/" "${this_dir}/${target_path%/}/" # filter out all symlinks
  else
    rm -rf "${this_dir}/${target_path}"
    mkdir -p "$(dirname "${this_dir}/${target_path}")"
    cp -v "${item}" "${this_dir}/${target_path}"
  fi
done

cd "${this_dir}"

if [ -z "$(git status --porcelain)" ]; then
  echo "[info] no new changes in this repository. Exit with zero status code."
  exit 0
fi

git add --all
git commit -m "[auto] configuration update $(date '+%Y-%m-%d')"
git push origin
