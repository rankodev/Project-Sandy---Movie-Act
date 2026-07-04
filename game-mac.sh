#!/bin/bash
cd "/Volumes/mvme/projects/PokemonStudio/psdk-binaries/ruby-dist"
source ./setup.sh
cd "/Volumes/mvme/projects/Project-Sandy---Movie-Act"
PSDK_BINARY_PATH="/Volumes/mvme/projects/PokemonStudio/psdk-binaries/" ruby Game.rb "$@"
