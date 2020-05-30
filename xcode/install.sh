#!/bin/zsh

# Install XCode
mas install 497799835
sudo xcodebuild -license accept
sudo xcodebuild -runFirstLaunch

# Install Cocoapods
sudo gem install cocoapods