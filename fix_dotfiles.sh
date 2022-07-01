#!/bin/bash
############################
# fix_dotfiles.sh
# This script recreates dotfiles symlinks, backing up any dotfiles in $HOME
# preventing a symlink to be created.
############################

colorize() { CODE=$1; shift; echo -e '\033[0;'$CODE'm'$*'\033[0m'; }
green() { echo -e "$(colorize 32 "$@")"; }
yellow() { echo -e "$(colorize 33 "$@")"; }

########## Variables
dotfiles_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/dotfiles"

files=`cd $dotfiles_dir && ls`    # list of files/folders to symlink in homedir

green "Reseting symlinks in $HOME to point to $dotfiles_dir/*"
for file in $files; do
    dotfile_path="$dotfiles_dir/$file"
    symlink_path="$HOME/.$file"
    if [[ ! -L $symlink_path ]]; then
        backup_dir=$HOME/.dotfile_backup
        mkdir -p $backup_dir
        yellow "Backing up existing non-symlinked dotfile to $HOME/.dotfile_backup"
        mv $symlink_path $backup_dir
    else
        yellow "Removing existing symlink at '$symlink_path'"
        unlink $symlink_path
    fi
    green "Creating symlink $dotfile_path -> $symlink_path"
    ln -s "$dotfile_path" "$symlink_path"
    echo
done

green "SUCCESS: dotfiles are configured"
