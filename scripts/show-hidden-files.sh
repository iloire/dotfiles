#!/bin/bash
#http://lifehacker.com/188892/show-hidden-files-in-finder

defaults write com.apple.finder AppleShowAllFiles TRUE
killall Finder
