#######################################################################
# SET WORKING DIRECTORY ###############################################

# Start by specifying the folder that you would like to work in. 
# Make sure that is also the place where the R-file collector is located
#setwd("C:/Kourosh/FinOpt/2013/Day08/Til kourosh/Til kourosh/Exercises + solutions")
setwd("C:/Kourosh/FinOpt/Liectenstein2013/ETF_Clustering")
source("collector.R")

#######################################################################
# DATA IS COLLECTED FROM finance.yahoo.com ############################
#######################################################################

# The csv file "instruments2.csv" containes tickets for 100 ETFs 
instr <- read.csv("instruments2.csv",sep = "\t")
assets <- as.character(instr$symbol)

# use the function Collector to gather historic data for the specified tickets.
# (This may take a minute or two dependant on your computer and internet connection)
# An internet connection is mandatory to download the data!  
data <- Collector(assets)

###################################################
###################################################
# Begin by investigating the data by looking some of the ETFs up on google and see what index they are replicating

# try plotting some of the time series
time <- as.Date(rownames(data))
plot(data[,1] ~ time, type = "l")

# calculate log returns
logr = log(data)
logr = apply(logr, 2, diff)


###################################################
###################################################
# now let us use the correlation to measure the distance between assets
#
# Here, we use the raw non-normalized data 

# First, we compute the correlation
c <- cor(logr, method="spearman")      # try using different kinds of correlations

# now we change the correlation coefficient to a distance
d <- as.dist(1-c)

# The function hclust() is then used to construct the tree 
hc <- hclust(d,method="complete")      # Try "single","complete","centroid","median"     
plot(hc)

# Can you see a difference between the correlation methods?


##################################################
##################################################
# Select the tree structure that you deem best and continue to work with that
#
# Use the function cutree to divide the different instruments into clusters

# Select a number of clusters
Cno <- 15 

# Cut the hirarchical tree to the desired number of clusters
memb <- cutree(hc, k = Cno)

# now that we have a tree and the different instruments are divided into clusters
# it is time to use a selection criteria and reduce the asset universe

Gselect <- rep(0,Cno)  # storage
time <- rownames(data) # time parameters

# The clusters are searched through and the best asset is chosen according to the selection criteria
# The index "i" is a given cluster. We can evaluate clusters in a number of ways. 
# Here, I have demonstrated how we can use either maximum return or 
# minimum standard deviation as a selection criteria

for(i in 1:Cno){
  Gnames <- names(which(memb == i))   # the names of the assets in clusters i
  
  criteria <- rep(0,length(Gnames))   # storage for the selection criteria
  
  for(j in 1:length(Gnames)){
    # The return is calculated for each asset in the given cluster "i"
    criteria[j] <- (data[1,Gnames[j]]-data[length(time),Gnames[j]])/data[length(time),Gnames[j]]
    
    # The standard deviation is calculated for each asset in the given cluster "i"
    # criteria[j] <- sd(data[,Gnames[j]])      
  }    
  # this is used when using maximum return as criteria
  Gselect[i] <- Gnames[which(max(criteria) == criteria)]
  
  # this is used when using minimum standard deviation as criteria
  #Gselect[i] <- Gnames[which(min(criteria) == criteria)]
}

# Now, let us look at our selected instruments
c <- cor(logr[,Gselect], method="spearman")
d <- as.dist(1-c)
#remember to use the same linkage method as you used for constructing the tree
hc <- hclust(d,method="complete")                   
plot(hc, hang = -1,xlab="Instruments", ylab="Spearman Distance")

# what instruments are included in the sub-universe using the different selection criteria?
# does is look reasonable?
# try using different number of clusters
# can you come up with another selection criteria?

#output log return data to .csv
write.csv2(logr[,Gselect],file='Filename.csv')


#Or output them in a format that GAMS likes:
logr2 <- logr[,Gselect]

sink("AssetReturns.inc")

for(j in 1:length(Gselect)) 
{
  for(i in 1:length(logr2[,1]))
  {
    cat(rownames(logr2)[i])
    cat(".")
    cat(Gselect[j])
    cat("\t")
    cat(logr2[i,j]) 
    cat("\n") 
  }  
}
sink()


