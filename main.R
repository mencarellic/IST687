## Load libraries, install if they aren't there
packageList <- c("ggplot2","doParallel", "randomForest", "wordcloud", "RColorBrewer", "foreach")
packageNew <- packageList[!(packageList %in% installed.packages()[,"Package"])]
if(length(packageNew)) install.packages(packageNew)
lapply(packageList, library, character.only = TRUE)
rm(packageNew,packageList)

## Setting seed now so I don't forget
set.seed(100)

## Read data from directory
data <- read.csv("data/aac_shelter_cat_outcome_eng.csv", na.strings="")

## Cleaning Data
## Dropping columns
dropCols <- c("animal_type", "age_upon_outcome","breed", "color", "monthyear", "age_group", "Cat.Kitten..outcome.", "sex_age_outcome", "Periods", "count", "Period.Range", "outcome_age_.years.", "coat", "dob_monthyear")
data <- data[,-which(names(data) %in% dropCols)]
rm(dropCols)

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

## Remove spaces from color1 and color2
## Reducing some color combinations
data$color1 <- gsub(" ","",data$color1)
data$color1<- gsub(".*tiger.*","tiger",data$color1)
data$color1<- gsub("silverlync","silver",data$color1)
data$color1<- gsub("bluecream","blue",data$color1)
data$color1<- gsub("apricot","cream",data$color1)
data$color1<- gsub("brownmerle","chocolate",data$color1)
data$color1<- gsub("fawn","cream",data$color1)
data$color1<- gsub("sable","black",data$color1)
data$color2 <- gsub(" ","",data$color2)
data$color2<- gsub(".*tiger.*","tiger",data$color2)
data$color2<- gsub("silverlync","silver",data$color2)
data$color2<- gsub("bluecream","blue",data$color2)
data$color2<- gsub("apricot","cream",data$color2)
data$color2<- gsub("brownmerle","chocolate",data$color2)

#### Transforming some nominal variables into binary
data$adoptBinary <- ifelse(tolower(data$outcome_type) %in% c("adoption"),1,0)
data$cfaBinary <- ifelse(data$cfa_breed==TRUE,1,0)
data$domesticBinary <- ifelse(data$domestic_breed==TRUE,1,0)

#### Drop NA adoptionBinary and outcome_type
data <- data[!is.na(data$outcome_type),]
data <- data[!is.na(data$adoptBinary),]



## Domestic only outcomes & Sampling
domesticOnlyData <- subset(data, domestic_breed==TRUE)
domesticOnlyData$color1 <- as.factor(domesticOnlyData$color1)
domesticOnlyData$color2 <- as.factor(domesticOnlyData$color2)
sampleSize <- floor(0.8 * nrow(domesticOnlyData))
domesticOnlyInd <- sample(seq_len(nrow(domesticOnlyData)), size=sampleSize)
domesticOnlyTrain <- domesticOnlyData[domesticOnlyInd,]
domesticOnlyTest <- domesticOnlyData[-domesticOnlyInd,]


##### Stats
## Total rows
totalRows <- nrow(data)


## CFA a factor in adoption?
cfa.Total <- length(which(data$cfa_breed==TRUE)) ## 1743
cfa.Adopted <- length(which(data$cfa_breed==TRUE&data$adoptBinary==1)) ## 823
cfa.NotAdopted <- length(which(data$cfa_breed==TRUE&data$adoptBinary==0)) ## 920
nonCFA.Total <- length(which(data$cfa_breed==FALSE)) ## 27675
nonCFA.Adopted <- length(which(data$cfa_breed==FALSE&data$adoptBinary==1)) ## 11909
nonCFA.NotAdopted <- length(which(data$cfa_breed==FALSE&data$adoptBinary==0)) ## 15766
adoptionRate.CFA <- cfa.Adopted / cfa.Total ## 0.4721744
adoptionRate.NonCFA <- nonCFA.Adopted / nonCFA.Total ## 0.4303162
adoptionRate.df <- data.frame(c(adoptionRate.CFA,adoptionRate.NonCFA))
rownames(adoptionRate.df) <- c("CFA Adoption", "Non CFA Adoption")
colnames(adoptionRate.df) <- "Rate"
## Bar plot
plot.CFA <- ggplot(adoptionRate.df, aes(x=rownames(adoptionRate.df), y=Rate)) +
  geom_bar(stat="identity") +
  scale_y_continuous(limits= c(0,1)) +
  labs(x="Cat Classification", y="Rate of Adoption") +
  ggtitle("Adoption Rates: CFA vs Non-CFA") +
  theme(plot.title = element_text(hjust = 0.5))

## Adoptions over time (by year)
aggDate <- aggregate(data$adoptBinary, by=list(data$outcome_year),sum)
## Remove 2013 and 2018 (incomplete years of data)
aggDate <- aggDate[-which(aggDate$Group.1==c(2013,2018)), ]
## Plotting
plot.AdoptionsOverTime <- ggplot(data=aggDate,aes(y=x,x=Group.1)) +
  geom_point() +
  geom_line() +
  labs(x="Year", y="Adoptions") +
  ggtitle("Adoptions Over Time") +
  theme(plot.title = element_text(hjust=0.5))

## Avg Outcome Age
data$trueAge <- difftime(as.Date(data$datetime), data$date_of_birth, units="days")
mean(data$trueAge)
mean(data$outcome_age_.days.) ## 509.4463 Days
aggOutcomesByAge <- aggregate(data$trueAge, by=list(data$outcome_type), mean)
plot.MeanOutcomeAge <- ggplot(data=aggOutcomesByAge, aes(y=x, x=Group.1)) +
  geom_bar(stat="identity") +
  scale_y_continuous() +
  labs(x="Outcome Type", y="Age at Outcome") +
  ggtitle("Average Age by Outcome Type (Days)") +
  theme(plot.title=element_text(hjust=0.5), axis.text.x=element_text(angle=45, hjust=1))
  

## Spay/Neuter
maleFixedCount <- length(which(data$Spay.Neuter == TRUE & data$sex == 'Male'))
femaleFixedCount <- length(which(data$Spay.Neuter == TRUE & data$sex == 'Female'))
maleFixed <- data[which(data$Spay.Neuter == TRUE & data$sex == 'Male'),]
femaleFixed <- data[which(data$Spay.Neuter == TRUE & data$sex == 'Female'),]
fixedStats <- with(data, table(sex,Spay.Neuter))
plot.FixedStats <- plot(fixedStats, main="Proportion of Spaying & Neutering",
                        xlab="Sex", ylab="Spayed / Neutered?")


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

## Name word cloud (Top 100)
aggNames.Sorted <- aggNames[order(-aggNames$count),]
wcColor <- brewer.pal(9, "BuGn")[-(1:2)]
wc.Names <- wordcloud(aggNames.Sorted$value, aggNames.Sorted$count, min.freq=1, scale=c(8,.4),
          max.words=Inf, random.order=FALSE, colors=wcColor)

## Number of outcomes per day
aggOutcomePerDay <- aggregate(data.frame(count=data$datetime), list(value=as.Date(data$datetime)), length)
aggAdoptionPerDay <- aggregate(data.frame(count=tolower(data$outcome_type)=="adoption"), list(value=as.Date(data$datetime),outcomeType=data$outcome_type), length)
plot.AdoptionsPerDay <- ggplot(data=aggAdoptionPerDay, aes(x=aggAdoptionPerDay$value,y=aggAdoptionPerDay$count)) +
  geom_point() + 
  labs(x="Year", y="Adoptions") +
  ggtitle("Adoptions Per Day") +
  theme(plot.title = element_text(hjust=0.5))




## Random forest for domestic only breeds
formula.RF <- as.formula(outcome_type~ sex + Spay.Neuter + outcome_weekday + outcome_hour)
fit.RF <- randomForest(formula.RF, domesticOnlyTrain, ntree=1000, mtry=4)
importance.RF <- importance(fit.RF)
pred.RF <- predict(fit.RF, domesticOnlyTest)

error.RF <- as.data.frame(cbind(domesticOnlyTest$outcome_type,pred.RF))
error.RF$correct <- ifelse(error.RF$V1==error.RF$pred.RF,TRUE,FALSE)
error.RFPercent <- sum(error.RF$correct==TRUE)/nrow(error.RF) ## 70.671% correct

## 2nd model. Takes about 5 minutes to run due to number of variables tried
formula.RF2 <- as.formula(outcome_type~ sex + Spay.Neuter + date_of_birth + outcome_weekday + outcome_hour + outcome_month + color1)
fit.RF2 <- randomForest(formula.RF2, domesticOnlyTrain, ntree=500, mtry=5)
importance.RF2 <- importance(fit.RF2)
pred.RF2 <- predict(fit.RF2, domesticOnlyTest)

error.RF2 <- as.data.frame(cbind(domesticOnlyTest$outcome_type,pred.RF2))
error.RF2$correct <- ifelse(error.RF2$V1==error.RF2$pred.RF,TRUE,FALSE)
error.RF2Percent <- sum(error.RF2$correct==TRUE)/nrow(error.RF2) ## 70.671% correct

