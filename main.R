## Load libraries, install if they aren't there
packageList <- c("ggplot2","neuralnet","e1071", "randomForest", "wordcloud", "RColorBrewer")
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
data$adoptBinary <- ifelse(tolower(data$outcome_type) %in% c("adoption"),1,0)
data$cfaBinary <- ifelse(data$cfa_breed==TRUE,1,0)
data$domesticBinary <- ifelse(data$domestic_breed==TRUE,1,0)

#### Drop NA adoptionBinary and outcome_type
data <- data[!is.na(data$outcome_type),]
data <- data[!is.na(data$adoptBinary),]



## Domestic only outcomes & Sampling
domesticOnlyData <- subset(data, domestic_breed==TRUE)
sampleSize <- floor(0.8 * nrow(domesticOnlyData))
set.seed(100)
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
ggplot(adoptionRate.df, aes(x=rownames(adoptionRate.df), y=Rate)) +
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
ggplot(data=aggDate,aes(y=x,x=Group.1)) +
  geom_point() +
  geom_line() +
  labs(x="Year", y="Adoptions") +
  ggtitle("Adoptions Over Time") +
  theme(plot.title = element_text(hjust=0.5))

## Avg Adoption Age
data$trueAge <- difftime(as.Date(data$datetime), data$date_of_birth, units="days")
mean(data$trueAge)
mean(data$outcome_age_.days.) ## 509.4463 Days
aggOutcomesByAge <- aggregate(data$trueAge, by=list(data$outcome_type), mean)
ggplot(data=aggOutcomesByAge, aes(y=x, x=Group.1)) +
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
plot(fixedStats, main="Proportion of Spaying & Neutering", xlab="Sex", ylab="Spayed / Neutered?")


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
wordcloud(aggNames.Sorted$value, aggNames.Sorted$count, min.freq=1, scale=c(8,.4),
          max.words=Inf, random.order=FALSE, colors=wcColor)

## Number of outcomes per day
aggOutcomePerDay <- aggregate(data.frame(count=data$datetime), list(value=as.Date(data$datetime)), length)
aggAdoptionPerDay <- aggregate(data.frame(count=tolower(data$outcome_type)=="adoption"), list(value=as.Date(data$datetime),outcomeType=data$outcome_type), length)
ggplot(data=aggAdoptionPerDay, aes(x=aggAdoptionPerDay$value,y=aggAdoptionPerDay$count)) +
  geom_point() + 
  labs(x="Year", y="Adoptions") +
  ggtitle("Adoptions Per Day") +
  theme(plot.title = element_text(hjust=0.5))
plot(x=aggAdoptionPerDay$value,y=aggAdoptionPerDay$count)


## Basic linear model
basicFormula <- as.formula(adoptBinary~ Spay.Neuter + trueAge + outcome_month + outcome_hour)
summary(lm(basicFormula,data=data))


## Logistic Regression
g <- glm(basicFormula,data=data,family='binomial')
summary(glm(basicFormula,data=data,family='binomial'))
curve(predict(g,data.frame(trueAge=x), type="resp"), add=TRUE)


## SVM
summary(svm(basicFormula,data=data))



## Random forest for domestic only breeds
formula.RF <- as.formula(outcome_type~ sex + Spay.Neuter + outcome_weekday + outcome_hour)
fit.RF <- randomForest(formula.RF, domesticOnlyTrain, ntree=500, keep.inbag=TRUE, importance=TRUE)
pred.RF <- predict(fit.RF, domesticOnlyTest)
error.RF <- as.data.frame(cbind(domesticOnlyTest$outcome_type,pred.RF))
error.RF$correct <- ifelse(error.RF$V1==error.RF$pred.RF,TRUE,FALSE)
sum(error.RF$correct==TRUE)/nrow(error.RF) ## 70.671% correct


