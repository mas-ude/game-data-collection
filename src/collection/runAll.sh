#!/bin/bash

FOLDER="$(date +%Y%m%d-%H%M%S)-GameCollection"
mkdir -p "$1/$FOLDER"

bash runMetacritic.sh "$1/$FOLDER"
bash runSteam.sh "$1/$FOLDER"
