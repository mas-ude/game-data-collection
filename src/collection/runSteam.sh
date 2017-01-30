Rscript steamSpyAPIdata.R | gawk '{ print strftime("[%Y-%m-%d %H:%M:%S]"), "[steamSpyAPIdata]", $0 }' 2>&1
Rscript steamAPIdata.R | gawk '{ print strftime("[%Y-%m-%d %H:%M:%S]"), "[steamAPIdata]", $0 }' 2>&1
