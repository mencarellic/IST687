## Austin Animal Shelter Data

### IST 687 Semester Project

Sourced from [https://www.kaggle.com/aaronschlegel/austin-animal-center-shelter-outcomes-and](https://www.kaggle.com/aaronschlegel/austin-animal-center-shelter-outcomes-and)

Dates: 10/1/2013 to 2/1/2018

### Technical Write Up

#### Library Loading
To make the running of this script easier, we implemented a method that checks installed packages and installs a package if it needs to be.

#### Setting the seed
This forces R to use the same seed when generating random numbers. This should allow for reproducable results

#### Loading the data
Very simple here, loading the data from the CSV and replacing all blanks with NA

#### Cleaning the data
##### Dropping extra columns
First thing is to reduce the size by dropping columns that are duplicated or concatenated from other columns. We use a special operator (%in%) to iterate through a vector containing the columns we want to drop.

##### Formatting datetimes
To allow better calculation of timeseries data, we changed the two datetime fields to POSIX calendar time which is a specification maintained by IEEE. 

##### Formatting logicals
Several fields are boolean in nature but not identified as such. Here we change the format of cfa_breed, domestic_breed, and Spay.Neuter to be boolean

##### Name cleansing
The names had several special characters that should be removed or replaced. gsub is an easy function that does the replacements quickly

##### Color aggregation
The data has two columns for colors of a cat. Some of these are extremely specific and can be generalized. Using gsub here again.

##### Creating some binary variables
While boolean variables are useful. Not all models seem to agree with boolean results so we're creating some binary variables

##### Removing NA's
There were three rows with NA for the outcome_type (which feeds adoptBinary). Removing these rows due to incomplete data

#### Data set creation
Modeling will be done on domestic cats which is the largest portion of the data. Here we're creating a subset with records that only have domestic_breed==TRUE. During the color aggreegation, the color1 and color2 fields were converted to chr, we need to transition them back to factors. 

Our train/test data set is an 80/20 split that is randomly sampled. Again results should be reproducible due to setting the seed on line 9

#### Statistical Analysis
##### Is being a CFA breed a factor in adoption?
CFA is Cat Fancier's Association. This is an association that recognizes 42 pedigreed breeds
This code is pretty simple. We gather a lot of totals and then gets the adoption rates for CFA breeds and non-CFA breeds. The info is put into a data frame and plotted it on a bar graph.

##### Adoptions over time by year
To gather this data, we count the number of outcomes for each year where the outcome is an adoption. We ended up dropping 2013 and 2018 since those were incomplete years. A line plot was chosen to display the data since it is a good fit for time series data.

##### Average age at outcome
The data provided a column for outcome age (in outcome_age.days.) but these values seem to be off when comparing to manually calculate ages between date of birth and outcome date time. To fix this a new column is created with the value being the difference between those two datetimes.

We choose to aggregate the data using the mean function to get the average age per outcome type and display those values in a bar plot.

##### Spay/Neuter Counts
We wanted to see if there was any interesting connections between sex and whether the pet was spayed or neutered so we created a stacked bar plot with sex and if they were spayed or neutered.

##### Various Other Stats
The next several lines of code are pretty simple means of things like outcome_hour, outcome_month, etc.

##### Finding the most frequent names and visualizing it
Again we use the aggregate function to count the number of occurances for each name. We then create a top 10 list by sorting that list by the count, descending.

Before generating the word cloud, I specify the color palette I want using RColorBrewer.

Generating the wordcloud for the first time was easy enough. Specify the data values and the data counts. That provided a word cloud, but ended up taking a long time to generate and wasn't sorted correctly. To correct this, we specified a minimum frequency for the name and changed the scale so more names would be able to fit on the cloud. We also specified to use as many words as the word cloud could and to use the color palette from RColorBrewer

##### Number of adoptions per day
Using the aggregate function, we were able to collect the number of adoptions that occurred each day and plotted it using a scatter plot.

#### RandomForest model and prediction
We ran two randomForest models and predictions based on those models. We're trying to predict the outcome_type based on various other data points.

The first model uses sex, Spay.Neuter, outcome_weekday, and outcome_hour with 1000 trees and trying all four variables. This is a pretty basic model that has a OOB error rate of 29.81% The issue with this run is that several of the outcome types that occur less have a 100% class.error

We ran a second model that uses sex, Spay.Neuter, color1, outcome_weekday, outcome_hour, date_of_birth, and outcome_month. We added another variable to try at each split but due to time constraints had to reduce the number of trees. This model had better results but still faced the same issue.

We calculated the error rate of each prediction model by calculating the number of values that are correctly predicted over all of the values in the data set.
