#!/bin/bash
if [ -h $HOME/.gitconfig ];
then
	echo 'git config EXISTS'
else
	echo 'installing git config...'
	ln -s $HOME/dotfiles/git/.gitconfig $HOME/.gitconfig
fi

if [ -h $HOME/.gitignore ];
then
	echo 'global git ignore EXISTS'
else
	echo 'installing global git ignore...'
	ln -s $HOME/dotfiles/git/.gitignore $HOME/.gitignore
fi

