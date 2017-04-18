#!/bin/bash

FOLDER="$(date +%Y%m%d-%H%M%S)-GameCollection"
mkdir -p $FOLDER

bash runMetacritc.sh $FOLDER
bash runSteam.sh $FOLDER
