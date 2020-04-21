#!/usr/bin/env bash

main() {
    ask_for_sudo
    install_xcode_command_line_tools # to get "git", needed for clone_dotfiles_repo
    clone_dotfiles_repo
    setup_gitconfig
    install_homebrew
    update_homebrew
    install_packages_with_brewfile
    symlink_dotfiles
    install_scripts
    update_system
    # update_hosts_file
    # setup_macOS_defaults
    # update_login_items
}

DOTFILES_REPO=~/.dotfiles
GIT_URL="https://github.com/undeadlegion/dotfiles"

function ask_for_sudo() {
    info "Prompting for sudo password"
    if sudo --validate; then
        # Keep-alive
        while true; do sudo --non-interactive true; \
            sleep 10; kill -0 "$$" || exit; done 2>/dev/null &
        success "Sudo password updated"
    else
        error "Sudo password update failed"
        exit 1
    fi
}

function install_xcode_command_line_tools() {
    info "Installing Xcode command line tools"
    os=$(sw_vers -productVersion | awk -F. '{print $1 "." $2}')
    IN_PROGRESS=/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress

    if softwareupdate --history | grep --silent "Command Line Tools"; then
        success "Xcode command line tools already exists"
    else
        touch ${IN_PROGRESS}
        product=$(softwareupdate --list | grep "\*.*Command Line" | tail -n 1 | sed 's/^.*: //')
        softwareupdate --install "${product}"
        rm ${IN_PROGRESS}

        if softwareupdate --history | grep --silent "Command Line Tools"; then
             success "Xcode command line tools successfully installed"
        else
            error "Xcode command line tools installation failed"
            exit 1
        fi
    fi
}

function install_xcode_command_line_tools_2() {
    if softwareupdate --history | grep --silent "Command Line Tools"; then
        success "Xcode command line tools already exists"
    else
        xcode-select --install
        read -n 1 -s -r -p "Press any key once installation is complete"

        if softwareupdate --history | grep --silent "Command Line Tools"; then
            success "Xcode command line tools installation succeeded"
        else
            error "Xcode command line tools installation failed"
            exit 1
        fi
    fi
}

function update_homebrew() {
    info "Updating Homebrew"
    brew update
    brew upgrade
    success "Homebrew successfully updated"
}

function update_system() {
    info "Updating System"
    softwareupdate -i -a
    success "System successfully updated"
}

function install_homebrew() {
    info "Installing Homebrew"
    if hash brew 2>/dev/null; then
        success "Homebrew already exists"
    else
        url=https://raw.githubusercontent.com/Homebrew/install/master/install.sh
        if yes | /bin/bash -c "$(curl -fsSL ${url})"; then
            success "Homebrew installation succeeded"
        else
            error "Homebrew installation failed"
            exit 1
        fi
    fi
}

function install_packages_with_brewfile() {
    info "Installing Brewfile packages"

    TAP=${DOTFILES_REPO}/brew/Brewfile_tap
    BREW=${DOTFILES_REPO}/brew/Brewfile_brew
    CASK=${DOTFILES_REPO}/brew/Brewfile_cask
    MAS=${DOTFILES_REPO}/brew/Brewfile_mas

    if hash parallel 2>/dev/null; then
        substep "parallel already exists"
    else
        if brew install parallel &> /dev/null; then
            printf 'will cite' | parallel --citation &> /dev/null
            substep "parallel installation succeeded"
        else
            error "parallel installation failed"
            exit 1
        fi
    fi

    if (echo $TAP; echo $BREW; echo $CASK; echo $MAS) | parallel --verbose --linebuffer -j 4 brew bundle check --file={} &> /dev/null; then
        success "Brewfile packages are already installed"
    else
        if brew bundle --file="$TAP"; then
            substep "Brewfile_tap installation succeeded"

            export HOMEBREW_CASK_OPTS="--no-quarantine"
            if (echo $BREW; echo $CASK; echo $MAS) | parallel --verbose --linebuffer -j 3 brew bundle --file={}; then
                success "Brewfile packages installation succeeded"
            else
                error "Brewfile packages installation failed"
                exit 1
            fi
        else
            error "Brewfile_tap installation failed"
            exit 1
        fi
    fi
}

function clone_dotfiles_repo() {
    info "Cloning dotfiles repository into ${DOTFILES_REPO}"
    if test -e $DOTFILES_REPO; then
        substep "${DOTFILES_REPO} already exists"
        pull_latest $DOTFILES_REPO
        success "Pull successful in ${DOTFILES_REPO} repository"
    else
        if git clone $GIT_URL $DOTFILES_REPO && \
           git -C $DOTFILES_REPO remote set-url origin $GIT_URL; then
            success "Dotfiles repository cloned into ${DOTFILES_REPO}"
        else
            error "Dotfiles repository cloning failed"
            exit 1
        fi
    fi
}

function setup_gitconfig() {
  if ! [ -f git/gitconfig.local.symlink ]
  then
    info 'Set up git config'

    git_credential='osxkeychain'

    substep 'What is your github author name?'
    read -e git_authorname
    substep 'What is your github author email?'
    read -e git_authoremail

    sed -e "s/AUTHORNAME/$git_authorname/g" -e "s/AUTHOREMAIL/$git_authoremail/g" -e "s/GIT_CREDENTIAL_HELPER/$git_credential/g" git/gitconfig.local.symlink.example > git/gitconfig.local.symlink

    success 'Git config set up successfully'
  fi
}

function pull_latest() {
    substep "Pulling latest changes in ${1} repository"
    if git -C $1 pull origin master &> /dev/null; then
        return
    else
        error "Please pull latest changes in ${1} repository manually"
    fi
}

function setup_symlinks() {
    APPLICATION_SUPPORT=~/Library/Application\ Support
    POWERLINE_ROOT_REPO=/usr/local/lib/python3.7/site-packages

    info "Setting up symlinks"
    symlink "git" ${DOTFILES_REPO}/git/gitconfig ~/.gitconfig
    symlink "hammerspoon" ${DOTFILES_REPO}/hammerspoon ~/.hammerspoon
    symlink "karabiner" ${DOTFILES_REPO}/karabiner ~/.config/karabiner
    symlink "powerline" ${DOTFILES_REPO}/powerline ${POWERLINE_ROOT_REPO}/powerline/config_files
    symlink "tmux" ${DOTFILES_REPO}/tmux/tmux.conf ~/.tmux.conf
    symlink "vim" ${DOTFILES_REPO}/vim/vimrc ~/.vimrc

    # Disable shell login message
    symlink "hushlogin" /dev/null ~/.hushlogin

    symlink "fish:completions" ${DOTFILES_REPO}/fish/completions ~/.config/fish/completions
    symlink "fish:functions"   ${DOTFILES_REPO}/fish/functions   ~/.config/fish/functions
    symlink "fish:config.fish" ${DOTFILES_REPO}/fish/config.fish ~/.config/fish/config.fish
    symlink "fish:oh_my_fish"  ${DOTFILES_REPO}/fish/oh_my_fish  ~/.config/omf

    success "Symlinks successfully setup"
}

function symlink() {
    application=$1
    point_to=$2
    destination=$3
    destination_dir=$(dirname "$destination")

    if test ! -e "$destination_dir"; then
        substep "Creating ${destination_dir}"
        mkdir -p "$destination_dir"
    fi
    if rm -rf "$destination" && ln -s "$point_to" "$destination"; then
        substep "Symlinking for \"${application}\" done"
    else
        error "Symlinking for \"${application}\" failed"
        exit 1
    fi
}

function link_file () {
    local src=$1 dst=$2

    local overwrite= backup= skip=
    local action=

    if [ -f "$dst" -o -d "$dst" -o -L "$dst" ]; then
        if [ "$overwrite_all" == "false" ] && [ "$backup_all" == "false" ] && [ "$skip_all" == "false" ]; then

            local currentSrc="$(readlink $dst)"

            if [ "$currentSrc" == "$src" ]; then
                skip=true;
            else
                substep "File already exists: $dst ($(basename "$src")), what do you want to do?"
                substep "[s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all?"
                read -n 1 action
                case "$action" in
                    o )
                        overwrite=true;;
                    O )
                        overwrite_all=true;;
                    b )
                        backup=true;;
                    B )
                        backup_all=true;;
                    s )
                        skip=true;;
                    S )
                        skip_all=true;;
                    * )
                        ;;
                esac
            fi
        fi

        overwrite=${overwrite:-$overwrite_all}
        backup=${backup:-$backup_all}
        skip=${skip:-$skip_all}

        if [ "$overwrite" == "true" ]; then
            rm -rf "$dst"
            success "removed $dst"
        fi

        if [ "$backup" == "true" ]; then
            mv "$dst" "${dst}.backup"
            success "moved $dst to ${dst}.backup"
        fi

        if [ "$skip" == "true" ]; then
            success "skipped $src"
        fi
    fi

    if [ "$skip" != "true" ]; then # "false" or empty
        ln -s "$1" "$2"
        success "linked $1 to $2"
    fi
}

function symlink_dotfiles () {
    info 'Installing Dotfiles'

    local overwrite_all=false backup_all=false skip_all=false

    for src in $(find -H "$DOTFILES_REPO" -maxdepth 2 -name '*.symlink' -not -path '*.git*'); do
        dst="$HOME/.$(basename "${src%.*}")"
        link_file "$src" "$dst"
    done
}

function install_scripts () {
    # find the installers and run them iteratively
    find . -name install.sh | while read installer ; do sh -c "${installer}" ; done
}

function update_hosts_file() {
    info "Updating /etc/hosts"
    own_hosts_file_path=${DOTFILES_REPO}/hosts/own_hosts_file
    ignored_keywords_path=${DOTFILES_REPO}/hosts/ignored_keywords
    downloaded_hosts_file_path=/etc/downloaded_hosts_file
    downloaded_updated_hosts_file_path=/etc/downloaded_updated_hosts_file

    if sudo cp "${own_hosts_file_path}" /etc/hosts; then
        substep "Copying ${own_hosts_file_path} to /etc/hosts succeeded"
    else
        error "Copying ${own_hosts_file_path} to /etc/hosts failed"
        exit 1
    fi

    if sudo wget --quiet --output-document="${downloaded_hosts_file_path}" \
        https://someonewhocares.org/hosts/hosts; then
        substep "hosts file downloaded successfully"

        if ack --invert-match "$(cat ${ignored_keywords_path})" "${downloaded_hosts_file_path}" | \
            sudo tee "${downloaded_updated_hosts_file_path}" > /dev/null; then
            substep "Ignored patterns successfully removed from downloaded hosts file"
        else
            error "Failed to remove ignored patterns from downloaded hosts file"
            exit 1
        fi

        if cat "${downloaded_updated_hosts_file_path}" | \
            sudo tee -a /etc/hosts > /dev/null; then
            success "/etc/hosts updated"
        else
            error "Failed to update /etc/hosts"
            exit 1
        fi

    else
        error "Failed to download hosts file"
        exit 1
    fi
}

function update_login_items() {
    info "Updating login items"

    if osascript ${DOTFILES_REPO}/macOS/login_items.applescript &> /dev/null; then
        success "Login items updated successfully "
    else
        error "Login items update failed"
        exit 1
    fi
}

function coloredEcho() {
    local exp="$1";
    local color="$2";
    local arrow="$3";
    if ! [[ $color =~ '^[0-9]$' ]] ; then
       case $(echo $color | tr '[:upper:]' '[:lower:]') in
        black) color=0 ;;
        red) color=1 ;;
        green) color=2 ;;
        yellow) color=3 ;;
        blue) color=4 ;;
        magenta) color=5 ;;
        cyan) color=6 ;;
        white|*) color=7 ;; # white or invalid color
       esac
    fi
    tput bold;
    tput setaf "$color";
    echo "$arrow $exp";
    tput sgr0;
}

function info() {
    coloredEcho "$1" blue "========>"
}

function substep() {
    coloredEcho "$1" magenta "===="
}

function success() {
    coloredEcho "$1" green "========>"
}

function error() {
    coloredEcho "$1" red "========>"
}

main "$@"
