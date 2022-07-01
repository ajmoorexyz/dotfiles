#!/bin/bash
############################
# install_dotfiles.sh
# This script creates symlinks from the home directory to any desired dotfiles in ~/dotfiles
############################

colorize() { CODE=$1; shift; echo -e '\033[0;'$CODE'm'$*'\033[0m'; }
bold() { echo -e "$(colorize 1 "$@")"; }
red() { echo -e "$(colorize '1;31' "$@")"; }
green() { echo -e "$(colorize 32 "$@")"; }
yellow() { echo -e "$(colorize 33 "$@")"; }


########## Variables
dir=$HOME/.dotfiles/dotfiles           # dotfiles directory
olddir=$HOME/.dotfiles_old            # old dotfiles backup directory

files="gitconfig gitignore_global rad-plugins zshrc"    # list of files/folders to symlink in homedir

########## Clone dotfiles
if [[ -d $HOME/.dotfiles ]]; then
  yellow "$HOME/.dotfiles exists.Skipping clone..."
else
  green "Cloning dotfiles into $HOME/.dotfiles"
  git clone https://github.com/truckfondue/dotfiles.git $HOME/.dotfiles
fi

# create dotfiles_old in homedir
green "Creating $olddir for backup of any existing dotfiles in ~"
mkdir -p $olddir
green "...done"

# change to the dotfiles directory
green "Changing to the $dir directory"
cd $dir
green "...done"

# move any existing dotfiles in homedir to dotfiles_old directory, then create symlinks
green "Moving any existing dotfiles from ~ to $olddir"
for file in $files; do
    mv ~/.$file $olddir 2>/dev/null
    echo "Creating symlink to $file in home directory"
    ln -s $dir/$file ~/.$file
done

green "SUCCESS: dotfiles are configured"
