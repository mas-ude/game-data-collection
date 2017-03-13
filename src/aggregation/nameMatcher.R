library(stringr)
library(stringdist)

datafolder <- "../../gamedata"

getNames <- function(serviceName, csvlookup) {
	service.files <- list.files(datafolder, pattern=paste(serviceName, ".\\d*.csv", sep=""))
	service.files <- service.files[order(file.mtime(service.files))]

	service.currentFile <- service.files[length(service.files)]

# print(service.currentFile)

	d <- read.csv(paste(datafolder, "/" , service.currentFile, sep=""),stringsAsFactors=FALSE, sep=";")

	return(csvlookup(d))
}

steamcsv <- function(csvdata){return(csvdata$"name")}
metacriticcsv <- function(csvdata){return(subset(csvdata, "pc" == csvdata$platform)$title)}
steam.names <- getNames("steamdata", steamcsv)
metacritic.names <- getNames("metacritic", metacriticcsv)

# Copy pure set
steam.namesCopy <- steam.names
metacritic.namesCopy <- metacritic.names

# Copyright and Trademark signs
steam.names <- gsub("<U\\+00AE>", "", steam.names)
steam.names <- gsub("<U\\+2122>", "", steam.names)

# unify strings
steam.names <- tolower(steam.names)
metacritic.names <-tolower(metacritic.names)

steam.names <- trimws(steam.names)
metacritic.names <- trimws(metacritic.names)

steam.names <- str_replace_all(steam.names, "[:-]", "")
metacritic.names <- str_replace_all(metacritic.names, "[:-]", "")

steam.names <- str_replace_all(steam.names, "  ", " ")
metacritic.names <- str_replace_all(metacritic.names, "  ", " ")

header <- c("Metacritc", "Steam")
steamMetacritic.list <- data.frame()
steamMetacritic.list <- names(header)

z <- 0
for(x in metacritic.names) {
	z <- z + 1
	row <- names(header)
	t <- match(x, steam.names)
	if (!is.na(t)) {
		row["Steam"] <- steam.namesCopy[t]
	} else {
		str <- ""
		for(sn in steam.names){
			sim <-stringsim(sn, x)
			if(sim > 0.8){
				str <- paste(str, sn ,";" , sim, ";", sep="")
			}
		}
		if(str == "") {
			str <- NA
		}
		row["Steam"] <- str
	}
	row["Metacritic"] <- metacritic.namesCopy[match(x, metacritic.names)]
	steamMetacritic.list <- rbind(row, steamMetacritic.list)
	if((z %% 10) == 0){
		cat(paste("#", z))
	}
}
