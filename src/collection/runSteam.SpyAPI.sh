#!/bin/bash
Rscript steamSpyAPIdata.R | gawk '{ print strftime("[%Y-%m-%d %H:%M:%S]"), "[steamSpyAPIdata]", $0 }' 2>&1
