## Require some base packages
require(RCurl)

## Gather data from Kaggle
loginURL <- "https://www.kaggle.com/account/login"
dataURL  <- "https://www.kaggle.com/aaronschlegel/austin-animal-center-shelter-outcomes-and/downloads/aac_shelter_cat_outcome_eng.csv"

tempDir = tempdir()
tempFile = tempfile(tmpdir=tempDir, fileext=".zip")

## Call file that contains the following:
## creds <- list(UserName="USERNAME",
##               Password="PASSWORD")
source("credentials.R")

agent <- "Mozilla/5.0"
curl = getCurlHandle()
curlSetOpt(cookiejar="cookies.txt",  useragent = agent, followlocation = TRUE, curl=curl)
welcome=postForm(loginURL, .params = creds, curl=curl)

bdown=function(url, file, curl){
  f = CFILE(file, mode="wb")
  curlPerform(url = url, writedata = f@ref, noprogress=FALSE, curl = curl)
  close(f)
}

ret = bdown(dataURL, tempFile,curl)

unzip(tempFile,exdir=tempDir)
name <- unzip(tempFile,list=TRUE)
filename <- paste(tempDir,"\\",name$Name,sep="")
data <- read.csv(filename)
