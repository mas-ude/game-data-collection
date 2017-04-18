#!/bin/bash

LOGFILE="/home/gamecrawler"

mkdir -p "$(date +%Y%m%d-%H%M%S)-GameCollection"

bash runMetacritc.sh
bash runSteam.sh
