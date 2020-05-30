#!/bin/zsh

LOCAL_PROJECTS_DIR="$HOME/Local"
PROJECTS_DIR="$HOME/Projects"

# Clone projects
git clone https://github.com/undeadlegion/AvaRoutines "$PROJECTS_DIR/ava_routines"
git clone https://jamlub1@bitbucket.org/avaascent/avaactions.git "$PROJECTS_DIR/AvaActions"
git clone https://jamlub1@bitbucket.org/avaascent/avaserver.git "$PROJECTS_DIR/AvaServer"
git clone https://jamlub1@bitbucket.org/avaascent/avatools.git "$PROJECTS_DIR/AvaTools"

# Clone external projects
git clone https://github.com/flutter/flutter.git "$LOCAL_PROJECTS_DIR/flutter"