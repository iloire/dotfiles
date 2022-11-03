#!/bin/bash
if [ -h $HOME/.zshrc ];
then
  echo 'zshrc EXISTS'
  echo 'you must remove .zshrc first'
else
  sudo apt install zsh
  echo 'installing .zshrc. cloning repo in ~/.oh-my-zsh ...'
  git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
  echo 'creating symbolic link ...'
  ln -s $HOME/dotfiles/shell/zshrc $HOME/.zshrc
  echo 'changing default logging shell to zsh ...'
  chsh -s /bin/zsh
  echo 'done!'
fi
