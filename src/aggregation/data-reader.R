#  setwd("git/game-data-collection")


df.priced <- data.frame()
csv.list <- Sys.glob("../../gamedata/steamdata-*.csv")
for (csv.file in csv.list) {
  print(csv.file)
  tmp <- read.csv(file=csv.file)
  date <- unlist(strsplit(unlist(strsplit(csv.file, split="-"))[2], split="\\."))[1]
  tmp$date <- date
  df.priced <- rbind(df.priced, tmp)
}
