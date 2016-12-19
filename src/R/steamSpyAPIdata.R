library(jsonlite)

cat("Starting scraping steamspy.\n")
steamspy.data <- fromJSON("http://steamspy.com/api.php?request=all")
cat("Processing scraped steamspy.\n")
d <- data.frame()
for (i in steamspy.data) {
  tmp <- data.frame(appid=i$appid, name=i$name, owners=i$owners, owners_variance=i$owners_variance, players_forever=i$players_forever, players_forever_variance=i$players_forever_variance, players_2weeks=i$players_2weeks, players_2weeks_variance=i$players_2weeks_variance, average_forever=i$average_forever, average_2weeks=i$average_2weeks, median_forever=i$median_forever, median_2weeks=i$median_2weeks)
  d <- rbind(d, tmp)
}

timestring <- format(Sys.time(), "%Y%H%M%S")
filename <- paste("data/steamSpydata.", timestring, ".csv", sep="")

cat(paste("Saving steamspy data in ",filename ,".\n", sep=""))

write.table(d, file=filename)
write.csv(d, file=filename, row.names=FALSE)
