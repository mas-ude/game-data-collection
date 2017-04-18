library(jsonlite)

# setwd("git/game-data-collection")

## TODO file pattern in a global const?
datafolder <- "."

steamSpy.files <- list.files(datafolder, pattern="steamSpyData.*.csv")
steamSpy.files <- steamSpy.files[order(file.mtime(steamSpy.files))]

steamSpy.currentFile <- steamSpy.files[length(steamSpy.files)]

d <- read.csv(paste(datafolder, "/" , steamSpy.currentFile, sep=""))

## get and package steamspy data
cat("Starting sorting for players\n")
## sort data by players, descending
d <- d[with(d, order(-players_forever)), ]

header <- c("appid", "name", "price", "currency", "is_free", "metacritic_score", "recommendations", "release_date" )
steamData <- data.frame(appid=as.Date(character()),
                 name=character(),
                 price=character(),
								 currency=character(),
								 is_free=character(),
								 metacritic_score=character(),
								 recommendations=character(),
								 release_date=character()
								 )

names(steamData) <- header

## Inital timestamp and csv file
timestring <- format(Sys.time(), "%Y%m%d%H%M%S")
filename <- paste(datafolder, "/steamdata.", timestring, ".csv", sep="")
exlusionsApiFilename <- paste(datafolder, "/steamdata.exlusions.", timestring, ".csv", sep="")


write.table(steamData, file=filename, sep=";")

## get current price data from steam
# (based on current IP: final (after sale) prices in EU region 1, in Euro)
cat("Scrapping price data from steam\n")
counter <- 0
waiter <- 1
for (i in 1:nrow(d)) {
	counter <- counter + 1
	row <- d[i,]
  # Skip "empty" app IDs
	if (is.na(row$appid)) {
    cat(i, "was NA")
		cat(":", row$appid, "\n")
    next
  }
	Sys.sleep(waiter) # steam storefront API is throttled to ~200requests/5mins

	## DEBUG BREAK
	## if(counter > 10)
	## break;

	retry <- TRUE
	while(retry) {
		cat(counter, "/",  nrow(d), "crawler at appid:", row$appid ," \n")
	  ## print(paste("http://store.steampowered.com/api/appdetails/?appids=",row$appid, sep=""))

		tmp <- NA
		returnTryCatch = tryCatch({
			tmp <- fromJSON(paste("http://store.steampowered.com/api/appdetails/?appids=",row$appid, sep=""))
		},
		error = function(err){cat("COMMUNICATION ERROR!\n")}
		)

		if(is.na(tmp)) {
			cat("Crawling failed. Timeout!\n")
			waiter <- max(1, waiter + 20)
			cat("Retry After", waiter , "Secounds\n")
			Sys.sleep(waiter)
			next
		}

		retry <- FALSE
		waiter <- max(0, waiter - 4)

		success <- tmp[[paste(row$appid)]]$success
		if (!success)
		{
			cat("Crawling failed. Not in API!\n")
			write(row$appid, file = exlusionsApiFilename, append = TRUE, sep = "\n")
			next;
		}

		price <- tmp[[paste(row$appid)]]$data$price_overview$final

  	if(!is.null(price)) {
    	row$price <- price
  	} else { # TODO: additionally check for is.free here!
    	row$price <- 0
  	}

		name <-tmp[[paste(row$appid)]]$data$name
		is_free <- tmp[[paste(row$appid)]]$data$is_free
		currency <-  tmp[[paste(row$appid)]]$data$currency
		if(is.null(currency)){
			currency <- ""
		}
		metacritic_score <- tmp[[paste(row$appid)]]$data$metacritic$score
		if(is.null(metacritic_score)){
			metacritic_score <- 0
		}
		recommendations <- tmp[[paste(row$appid)]]$data$recommendations$total
		if(is.null(recommendations)){
			recommendations <- 0
		}
		release_date <-  tmp[[paste(row$appid)]]$data$release_date$date
		if(is.null(release_date)){
			release_date <- ""
		}

		## data.framing
		steamDataRow <- data.frame(row$appid, name, row$price, currency, is_free, metacritic_score, recommendations, release_date)
		names(steamDataRow) <- header
		## steamData <- rbind(steamData, steamDataRow)

		write.table(steamDataRow, file=filename, sep=";", col.names=FALSE, row.names=FALSE, append=TRUE)
	}
}
