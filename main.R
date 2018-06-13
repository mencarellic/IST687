## Load libraries, install if they aren't there
packageList <- c("ggplot2")
packageNew <- packageList[!(packageList %in% installed.packages()[,"Package"])]
if(length(packageNew)) install.packages(packageNew)
lapply(packageList, library, character.only = TRUE)
rm(packageNew,packageList)


## Read data from directory
data <- read.csv("data/aac_shelter_cat_outcome_eng.csv", na.strings="")

## Cleaning Data
## Dropping columns
dropCols <- c("animal_type", "age_upon_outcome","breed", "color", "monthyear", "age_group", "Cat.Kitten..outcome.", "sex_age_outcome", "Periods", "count", "Period.Range", "outcome_age_.years.", "coat", "dob_monthyear")
data <- data[,-which(names(data) %in% dropCols)]

## Formatting DOB & Datetime
data$date_of_birth <- as.POSIXct(as.character(data$date_of_birth), format="%Y-%m-%d")
data$datetime <- as.POSIXct(as.character(data$datetime), format="%Y-%m-%d %H:%M:%S")

## Formatting logicals
data$cfa_breed = as.logical(data$cfa_breed)
data$domestic_breed = as.logical(data$domestic_breed)
## Change spay/neuter status to a logical
data$Spay.Neuter = gsub('Yes','True',data$Spay.Neuter)
data$Spay.Neuter = gsub('No','False',data$Spay.Neuter)
data$Spay.Neuter = as.logical(data$Spay.Neuter)

## Remove * from Names
data$name <- gsub("\\*","",data$name)


#### Transforming some nominal variables into binary
data$adoptBinary <- ifelse(tolower(data$outcome_type)=="adoption",1,0)

### Splitting coat_pattern into binary variables
newdata <- cbind(data[1:20], sapply(levels(data$coat_pattern),function(x) as.integer(x==data$coat_pattern)), data[22:24])



##### Stats
## Total rows
totalRows <- nrow(data)

## Avg Dropoff Age
### Possible?

## CFA a factor in adoption?
cfa.Total <- length(which(data$cfa_breed==TRUE)) ## 1743
cfa.Adopted <- length(which(data$cfa_breed==TRUE&data$adoptBinary==1)) ## 823
cfa.NotAdopted <- length(which(data$cfa_breed==TRUE&data$adoptBinary==0)) ## 920
nonCFA.Adopted <- length(which(data$cfa_breed==FALSE&data$adoptBinary==1)) ## 11909
nonCFA.NotAdopted <- length(which(data$cfa_breed==FALSE&data$adoptBinary==0)) ## 15766


## Adoptions over time (by year)
aggDate <- aggregate(data$adoptBinary, by=list(data$outcome_year),sum)
## Seems to be missing 2017 for some reason??

## Avg Adoption Age
mean(data$outcome_age_.days.) ## 509.4463 Days

## Spay/Neuter
maleFixedCount <- length(which(data$Spay.Neuter == TRUE & data$sex == 'Male'))
femaleFixedCount <- length(which(data$Spay.Neuter == TRUE & data$sex == 'Female'))
maleFixed <- data[which(data$Spay.Neuter == TRUE & data$sex == 'Male'),]
femaleFixed <- data[which(data$Spay.Neuter == TRUE & data$sex == 'Female'),]
fixedStats <- with(data, table(sex,Spay.Neuter))

## Adoption Days
outcomeDays <- as.data.frame(table(data$outcome_weekday))
colnames(outcomeDays) <- c("Weekday","Count")

## Average outcome hour
outcomeHour <- mean(data$outcome_hour)

## Average outcome month
outcomeMonth <- mean(data$outcome_month)

## Average dob month
dobMonth <- mean(data$dob_month)

## Average number of days between birth and outcome
mean(round(difftime(data$datetime,data$date_of_birth,units="days"))) ## 534.4272 days

## Count number of pets named certain names
aggNames <- aggregate(data.frame(count=data$name), list(value=data$name),length)
aggNames.Top10 <- head(aggNames[order(aggNames$count,decreasing=TRUE),],n=10)

length(which(data$name=="Charlie" & data$sex=="Male"))/nrow(data)
length(which(data$name=="Charlie" & data$sex=="Female"))/nrow(data)

length(which(data$name %in% aggNames.Top10$value & data$sex=="Male"))/nrow(data)

## Number of outcomes per day
aggOutcomePerDay <- aggregate(data.frame(count=data$datetime), list(value=as.Date(data$datetime)), length)
aggAdoptionPerDay <- aggregate(data.frame(count=tolower(data$outcome_type)=="adoption"), list(value=as.Date(data$datetime),outcomeType=data$outcome_type), length)
plot(x=aggAdoptionPerDay$value,y=aggAdoptionPerDay$count)