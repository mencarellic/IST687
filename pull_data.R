## Require some base packages
require(RCurl)

## Set some base variables
loginURL <- "https://www.kaggle.com/account/login"
dataURL  <- "https://www.kaggle.com/aaronschlegel/austin-animal-center-shelter-outcomes-and/downloads/aac_shelter_cat_outcome_eng.csv"
tempDir = tempdir()
tempFile = tempfile(tmpdir=tempDir, fileext=".zip")
cookieFile = tempfile(tmpdir=tempDir, fileext=".txt")
agent <- "Mozilla/5.0"

## Call file that contains the following:
## creds <- list(UserName="USERNAME",
##               Password="PASSWORD")
source("credentials.R")

## Curl options and the logging into Kaggle
curl = getCurlHandle()
curlSetOpt(cookiejar=cookieFile, useragent=agent, followlocation=TRUE, curl=curl)
welcome=postForm(loginURL, .params= creds, curl=curl)


## Download file
f = CFILE(tempFile, mode="wb")
curlPerform(url=dataURL, writedata=f@ref, noprogress=TRUE, curl=curl)
close(f)

## Unzip file and load into df
unzip(tempFile, exdir=tempDir)
name <- unzip(tempFile, list=TRUE)
filename <- paste(tempDir, "\\", name$Name, sep="")
data <- read.csv(filename, na.strings="")


##Cleanup and GC
remove(creds,curl,name,agent,dataURL,f,filename,loginURL,tempDir,tempFile,welcome,cookieFile)
gc()

