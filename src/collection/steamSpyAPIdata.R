library(jsonlite)
library(optparse)
library(logging)

option_list = list(
  make_option(c("-o", "--output"), action="store", type="character", default=".",
              help="folder to write data in", metavar="character")
)

opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)

datafolder <- opt$output

basicConfig()
addHandler(writeToFile, file= paste(opt$output, "/steamSpyAPI.log", sep=""))

loginfo(paste("data folder: \"", datafolder ,"\" will be used.\n", sep=""))


if (!file.exists(datafolder)) {
	loginfo(paste("data folder: \"", datafolder ,"\" sould be created.\n", sep=""))
	q()
}

loginfo("Start scraping steamspy.\n")
steamspy.data <- fromJSON("http://steamspy.com/api.php?request=all")
loginfo("Processing scraped steamspy.\n")
d <- data.frame()
for (i in steamspy.data) {
  tmp <- data.frame(appid=i$appid, name=i$name, owners=i$owners, owners_variance=i$owners_variance, players_forever=i$players_forever, players_forever_variance=i$players_forever_variance, players_2weeks=i$players_2weeks, players_2weeks_variance=i$players_2weeks_variance, average_forever=i$average_forever, average_2weeks=i$average_2weeks, median_forever=i$median_forever, median_2weeks=i$median_2weeks)
  d <- rbind(d, tmp)
}

timestring <- format(Sys.time(), "%Y%m%d%H%M%S")
filename <- paste(datafolder, "/steamSpyData.", timestring, ".csv", sep="")

loginfo(paste("Saving steamspy data in ",filename ,".\n", sep=""))

write.csv(d, file=filename, row.names=FALSE)
