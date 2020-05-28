
cd "$(dirname "$0")";

cat ./extensions.txt | xargs -n 1 code --install-extension
ln -s ./Library/Application\ Support/Code/User/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json
ln -s ./Library/Application\ Support/Code/User/settings.json ~/Library/Application\ Support/Code/User/settings.json