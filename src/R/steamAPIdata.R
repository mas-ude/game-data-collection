library(jsonlite)


## TODO path in a globle const?
## TODO file pattern in a global const?
steamSpy.files <- list.files("data", pattern="steamSpydata.*.csv")
steamSpy.files <- steamSpy.files[order(file.mtime(steamSpy.files))]

steamSpy.currentFile <-  steamSpy.files[1]

d <- read.csv(paste("data/", steamSpy.currentFile, sep=""))

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

## get current price data from steam
# (based on current IP: final (after sale) prices in EU region 1, in Euro)
cat("Scrapping price data from steam\n")
counter <- 0
for (i in 1:nrow(d)) {
	counter <- counter + 1
	row <- d[i,]
  # Skip "empty" app IDs
	if (is.na(row$appid)) {
    cat(i, "was NA")
		cat(":", row$appid, "\n")
    next
  }
	Sys.sleep(1) # steam storefront API is throttled to ~200requests/5mins

	## DEBUG BREAK
	## if(counter > 10)
	## break;

	retry <- TRUE
	while(retry) {
		cat(counter, "/",  nrow(d), "\n")
	  ## print(paste("http://store.steampowered.com/api/appdetails/?appids=",row$appid, sep=""))
	  tmp <- fromJSON(paste("http://store.steampowered.com/api/appdetails/?appids=",row$appid, sep=""))
		success <- tmp[[paste(row$appid)]]$success
		## print(success)
		if(success){
			retry <- FALSE
			waiter <- 1
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
				steamData <- rbind(steamData, steamDataRow)
		}
		else{
			## retry after 5 else
			cat("Retry\n")
			waiter <- waiter*2
			Sys.sleep(waiter)
		}
	}
}

## TODO: Only saves after everything is fatched. Should save gradually?
timestring <- format(Sys.time(), "%Y%H%M%S")
filename <- paste("data/steamdata.", timestring, ".csv", sep="")

cat(paste("Saving steam data in ",filename ,".\n", sep=""))

write.table(steamData, file=filename)
write.csv(steamData, filename, row.names=FALSE)
