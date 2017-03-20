library(stringr)
library(stringdist)
library(foreach)

datafolder <- "../../gamedata"

getNames <- function(serviceName, csvlookup) {
	service.files <- list.files(datafolder, pattern=paste(serviceName, ".\\d*.csv", sep=""))
	service.files <- service.files[order(file.mtime(service.files), decreasing = TRUE)]

	service.currentFile <- service.files[1]

print(service.currentFile)

	d <- read.csv(paste(datafolder, "/" , service.currentFile, sep=""),stringsAsFactors=FALSE, sep=";")

	return(csvlookup(d))
}

steamcsv <- function(csvdata){return(csvdata$"name")}
metacriticcsv <- function(csvdata){return(subset(csvdata, "pc" == csvdata$platform)$title)}
steam.names <- getNames("steamdata", steamcsv)
metacritic.names <- getNames("metacritic", metacriticcsv)

# Copy pure set
steam.unmodified.names <- steam.names
metacritic.unmodified.names <- metacritic.names

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

# do two step matching
header <- c("Metacritc", "Steam")
steamMetacritic.list <- data.frame()
steamMetacritic.list <- names(header)

metacritic.names.left <- c()

datafolder <- "../../gamedata"
timestring <- format(Sys.time(), "%Y%m%d%H%M%S")

print("Step 1")
# Try one to one match first. All success are removed from list
for(x in metacritic.names) {
	t <- match(x, steam.names)
	if (!is.na(t)) {
	  row <- names(header)
	  row["Metacritic"] <- metacritic.unmodified.names[match(x, metacritic.names)]
	  row["Steam"] <- steam.unmodified.names[t]
		steam.unmodified.names <- steam.unmodified.names[-t]
		steam.names <- steam.names[-t]
		steamMetacritic.list <- rbind(row, steamMetacritic.list)
	} else {
		# No match. calculate possible matches in next step.
		metacritic.names.left <- c(metacritic.names.left, x)
	}
}

filename <- paste(datafolder, "/matchedMetacritcToSteam.resolved.", timestring, ".csv", sep="")
write.table(steamMetacritic.list, file=filename, sep=";", col.names=TRUE, row.names=FALSE)


maxVariants <- 10
header <- c("Metacritc","VariantCount")

for(count in 1:maxVariants){
	c(header, paste("Steam", count, sep=""))
}

steamMetacritic.unresolved.list <- data.frame()
steamMetacritic.unresolved.list <- names(header)

print("Step 2")
# Do string dist for the left once
z <- 0
cat("Still left: ")
print(length(metacritic.names.left))
for(x in metacritic.names.left) {
	z <- z + 1
	row <- names(header)
	row["Metacritic"] <- metacritic.unmodified.names[match(x, metacritic.names)]
	row["VariantCount"] <- 0
	i <- 0
	for(count in 1:maxVariants)
	{
		row[paste("Steam", count, sep="")] <- NA
	}

	variants <- data.frame(stringsAsFactors=FALSE)
	variants <- names(c("Variant","Simularity"))

	for(sn in steam.names){
		sim <-stringsim(sn, x)
		if(sim > 0.6) {
			v <- names(c("Variant","Simularity"))
			v["Variant"] <-  steam.unmodified.names[match(sn, steam.names)]
			v["Simularity"] <- sim
			variants <- rbind(variants, v)
		}
	}

	if(length(variants) != 0){
		variants.sorted <- variants[order(variants[,"Simularity"], decreasing = TRUE),]
		if(length(variants.sorted) == 2){ # WTF R
				row["Steam1"] <- variants.sorted["Variant"]
				row["VariantCount"] <- 1
		}
		else {
			variants.names <- variants.sorted[1:min(maxVariants, length(variants.sorted[,"Variant"])),"Variant"]
			i <- 0
			foreach(v = variants.names) %do% {
				i <- i + 1
	  		row[paste("Steam", i, sep="")] <- v
			}
			row["VariantCount"] <- i
		}
	}

	steamMetacritic.unresolved.list <- rbind(row, steamMetacritic.unresolved.list)
	if((z %% 10) == 0){
		cat(paste("#", z))
	}
	if(z == 100){
		break;
	}
}

filename <- paste(datafolder, "/matchedMetacritcToSteam.unresolved.", timestring, ".csv", sep="")
#write.table(steamMetacritic.unresolved.list, file=filename, sep=";", col.names=TRUE, row.names=FALSE)
write.csv(steamMetacritic.unresolved.list, file=datafolder)
