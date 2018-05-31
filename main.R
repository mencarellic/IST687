## Download data and put into dataframe
source("pull_data.R")


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
