Collector <- function(assets){
  
  # Some might need to install the package 'RCurl'
  #install.packages("RCurl")
  
  # Today's date
  Day <- as.POSIXlt(Sys.time())$mday
  Month <-  as.POSIXlt(Sys.time())$mon
  Year <- 1900 + as.POSIXlt(Sys.time())$year
  
  # Today's date from 8 years ago
  sDay <- Day          
  sMonth <-  Month     		
  sYear <- Year-8 
  
  data <- list()
  for(i in 1:(length(assets))){
    asset <- assets[i]
    URLdata  <- paste("http://ichart.finance.yahoo.com/table.csv?s=",asset,"&a=",sDay,"&b=",sMonth,"&c=",sYear,"&d=",Day,"&e=",Month,"&f=",Year,"&g=w&ignore=.csv")
    URLdata  <- gsub(" ","", URLdata , fixed=TRUE) # Problem in URL fixed
    data[[i]] <- read.csv(url(URLdata))$Close
  }
  
  lengths <- c(1:length(assets))
  for(i in 1:(length(assets))){
    lengths[i] <- length(data[[i]])
  }
  
  minlength <- min(lengths)
  time <- as.character(read.csv(url(URLdata))$Date)[1:minlength]
  data2 <- array(0,dim=c(minlength,length(assets)))
  
  for(i in 1:(length(assets))){
    data2[,i] <- data[[i]][1:minlength]  
  }
  
  dimnames(data2) = list(time,assets)
  data2 <- data2[length(data2[,1]):1,]
  return(data2)
}
