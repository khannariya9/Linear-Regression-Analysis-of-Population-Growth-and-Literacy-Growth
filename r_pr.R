library("viridisLite")
library(highcharter)
library(ggplot2)
library(dplyr)
library(tidyr)
library(viridis)
library(scales)
library(gridExtra)
library(grid)

allData <- read.csv("Census_data.csv",stringsAsFactors = FALSE, header = TRUE, na.strings=c("","-","NA"))
attach(allData)

allData[is.na(allData)] <- 0


prev_growth = as.numeric(allData$Growth..1991...2001.)/100
allData["prev_populations"] = as.numeric(allData$Persons)*(1-prev_growth)
allData["HouseholdSize2"] = as.numeric(allData$Persons)/(as.numeric(allData$Number.of.households))

allData$HouseholdSize2[which(!is.finite(allData$HouseholdSize2))] <- 0

percent <- function(x,y,...){
  return((sum(x)/sum(y))*100)
}
percent2 <- function(x,y,...){
  return((x/y)*100)
}

states <- allData %>% group_by(State) %>% 
  summarise(Total = n(), 
            Population = sum(Persons),
            TotalVillages = sum(Total.Inhabited.Villages),
            GrowthRate = ((sum(as.numeric(Persons))- sum(prev_populations))/sum(prev_populations)*100),
            LiteracyRate = percent(Persons..literate,Persons),
            GrowthRateInv = 1/((sum(as.numeric(Persons))- sum(prev_populations))/sum(prev_populations)),
            # TotalRural = percent(Rural,Persons)
            # TotalUrban = percent(Urban,Persons),
            # TotalHH = percent(Number.of.households,Persons),
            # TotalSTPop = percent(Scheduled.Tribe.population,Persons),
            # TotalLite = percent(Persons..literate,Persons),
            # TotalGrad = percent(Graduate.and.Above,Persons),
            Totalworkers = percent(Total.workers,Persons),
            TotalHCC = percent2(sum(as.numeric(Medical.facility)), TotalVillages),
            TotalEduPri = percent2(sum(as.numeric(Primary.school)),TotalVillages),
            TotalEduMid = percent2(sum(as.numeric(Middle.schools)),TotalVillages),
            TotalEduSec = percent2(sum(as.numeric(Secondary.Sr.Secondary.schools)),TotalVillages),
            SexRatio_0_6 = mean(as.numeric(Sex.ratio..females.per.1000.males.)),
            HHSize = mean(as.numeric(HouseholdSize2)), 
            TotalElecVill = percent2(sum(Electricity..Power.Supply.), TotalVillages),
            TotalDrinkingWater = percent2(sum(Drinking.water.facilities), TotalVillages),
            TotalComm = percent2(sum(Post..telegraph.and.telephone.facility), TotalVillages),
            TotalBus = percent2(sum(Bus.services), TotalVillages),
            TotalPavedRoad = percent2(sum(Paved.approach.road), TotalVillages),
            TotalPermHome = mean(Permanent.House)
  )        

detach(allData)

  
"Census data is collected by the Government of India every decade. This mammoth task is 
undertaken every 10 years to count of all people in India and recording basic demographic 
information. This data has been processed and organized into district-wise grouping.

One of the biggest problems being faced by India is the reduction in per-capita resources 
resulting from high population growth which inturn affects general living conditions in a 
ripple-fashion. This analysis aims to identify amenities to be improved by the government to uplift the country's living conditions, especially by targeting 
growth rate. Let's begin by testing a hypothesis that growth rate and literacy rate are 
inversely related. "

  
"The growth is unusually high in 4 - 5 states, most of which are union territories
and are small in area and sparsely populated. Data for these outliers was removed for 
most of the analysis in this report."




ggplot(data=states) +
  geom_bar(aes(x=State, y=GrowthRate), stat="identity", width=0.5) +
  ylab("Growth Rate") +
  ggtitle("Growth Rate per State") +
  theme(axis.text.x = element_text(angle = 60, hjust = 1, size = 7), aspect.ratio = 0.9, axis.ticks = element_blank())



  
"Kerala and Tamil Nadu have the least growth rate of around 10-15%. They are both fairly 
large and well developed states, so one would expect that this less growth rate would be 
closely related to high literacy rate, low unemployment rate and higher basic amenities.
The graph below shows the literacy rate per state."


ggplot(data=states) +
  geom_bar(aes(x=State, y=LiteracyRate), stat="identity", width=0.5) +
  ylab("Literacy Rate") +
  ggtitle("Literacy Rate per State") +
  theme(axis.text.x = element_text(angle = 60, hjust = 1, size = 7), aspect.ratio = 0.9, axis.ticks = element_blank())

" Regression Analysis 
  
  Tamilnadu's literacy rate falls below average, whereas Kerala stands first in growth rate 
and literacy rate. But Kerala's parameters can not be simply studied and replicated as a 
'one size fits all' solution to improve a large diverse country like India. So, let us study
the country in a state-wise fashion to identify the parameters which have a large effect on
growth rate. Regression analyses are used through the paper to identify such factors.

Linear regression models with Growth rate and Growth rate inverse against Literacy rate were used 
to better visualize the regression lines. Below are the results for linear regression for 
both the models."

statesTrim = subset(states, GrowthRate < 65)

attach(statesTrim)

reg1 = lm(GrowthRate~LiteracyRate) ; summary(reg1)

p_val1 =summary(reg1)$coef[2,4]
r_sq1 = summary(reg1)$r.squared
std_err1 = summary(reg1)$sigma/mean(GrowthRate)

reg2 = lm(GrowthRateInv ~LiteracyRate) ; summary(reg2)
p_val2 =summary(reg2)$coef[2,4]
r_sq2 = summary(reg2)$r.squared
std_err2 = summary(reg2)$sigma/mean(GrowthRateInv)



par(mfrow=c(2,2))
#par(mar=c(1,1,1,1))
main_cex = 0.75
plot(x = LiteracyRate, y= GrowthRate, ylim = c(1,60), xlab = "Literacy Rate (%)", ylab ="Growth Rate (%)", main = paste("Regression model of Literacy Rate vs. Growth Rate", "\n P Value:", round(p_val1,4), "  R Squared:", round(r_sq1,4)), cex.lab=main_cex, cex.axis=main_cex, cex.main=main_cex, cex.sub=main_cex, pch = 16)
abline(reg1)

plot(x = LiteracyRate, y= GrowthRateInv, xlab = "Literacy Rate (%)", ylab ="100/Growth Rate", main = paste("Regression model of Literacy Rate vs. 100/Growth Rate", "\n P Value:", round(p_val2,4), "  R Squared:", round(r_sq2,4)), cex.lab=main_cex, cex.axis=main_cex, cex.main=main_cex, cex.sub=main_cex, pch = 16)
abline(reg2)

plot(x= GrowthRate, y= reg1$fitted.values, xlim = c(10,50), ylim= c(10 ,50), ylab ="Fitted Growth Rate", main= "Testing fit of Literacy~Growth Regression", cex.lab=main_cex, cex.axis=main_cex, cex.main=main_cex, cex.sub=main_cex, pch = 16)
abline(0,1)

plot(x= GrowthRateInv , y = reg2$fitted.values, xlim=c(1,10), ylim = c(1,10), ylab ="Fitted Growth Rate Inverse", main = "Testing fit of Literacy~GrowthInverse Regerssion", cex.lab=main_cex, cex.axis=main_cex, cex.main=main_cex, cex.sub=main_cex, pch = 16)
abline(0,1)

"From the above sensitivity tests, it is clear that Growth Rate Inverse is a better fit for linear regression with Literacy Rate.
A multiple regression analysis was run for Growth Rate Inverse and all other parameters, then run through a step function to choose a subset
of best possible predictor variables from the input data."

" Multiple Regression Analysis 
 The full regression model was developed for Growth Rate Inverse against all the 10 other variables.
The AIC function was used for the step-wise elimination; eventually arriving at the two variables 
that have the most significance without hurting the fit of the model. The variables selected were 
the Secondary Education Rate and Household Size. "


regr_vars_j = c("GrowthRate", "GrowthRateInv", "LiteracyRate", "Totalworkers", "SexRatio_0_6")

regr_vars_i = c("TotalEduPri", "TotalEduMid", "TotalEduSec",  "TotalHCC", "TotalElecVill", "TotalComm","TotalBus", "TotalPavedRoad", "TotalPermHome", "HHSize" )



p_val <- matrix(nrow=length(regr_vars_i), ncol=length(regr_vars_j), byrow=TRUE)
r_sq <- matrix(nrow=length(regr_vars_i), ncol=length(regr_vars_j), byrow=TRUE)
std_err <- matrix(nrow=length(regr_vars_i), ncol=length(regr_vars_j), byrow=TRUE)
slope <- matrix(nrow=length(regr_vars_i), ncol=length(regr_vars_j), byrow=TRUE)
for (i in c(1:length(regr_vars_i))) {
  for (j in c(1:length(regr_vars_j))) {
    var1 = get(regr_vars_i[i])
    var2 = get(regr_vars_j[j])
    
    mulReg= lm(var1~var2)
    p_val_temp =summary(mulReg)$coef[2,4]
    r_sq_temp = summary(mulReg)$r.squared
    std_err_temp = summary(mulReg)$sigma/mean(var1)
    p_val[i,j] = p_val_temp
    r_sq[i,j] = r_sq_temp
    std_err[i,j] = std_err_temp
    slope[i,j] = mulReg$coefficients[[2]]
  }
}

rownames(p_val) = regr_vars_i
colnames(p_val) = regr_vars_j

rownames(r_sq) = regr_vars_i
colnames(r_sq) = regr_vars_j

p_val
r_sq



fit_all = lm(GrowthRateInv ~ TotalEduPri + TotalEduMid + TotalEduSec + TotalHCC + TotalElecVill + TotalComm + TotalBus + TotalPavedRoad + TotalPermHome + HHSize)

#summary(fit_all)

stepFunc = step(fit_all)

summary(stepFunc)

plot(x = GrowthRateInv, y=fit_all$fitted.values , xlim=c(1,10), ylim=c(1,10), ylab = "Fitted Values", xlab = "Growth Rate Inverse", main = "Full Model Linear Regression - Test of Fit")
abline(0,1)

plot(x = GrowthRateInv, y=stepFunc$fitted.values , xlim=c(1,10), ylim=c(1,10), ylab = "Fitted Values", xlab = "Growth Rate Inverse", main = "Pruned Model Linear Regression - Test of Fit")
abline(0,1)




" Out of Sample Validation 
  Now let us test the accuracy of the results by running Out of Sample Validation tests. Linear 
models were created for both Growth Rate and Inverse against the 2 predictor variables. From the 
plots below, it is clear that the two predictor variables have significant effect on Growth.
Also, the out of sample accuracy is higher with Growth Rate Inverse than with Growth Rate."




main_cex = 0.75

trainingRows = sample(1:35, size=26)

trainingData = statesTrim[trainingRows, ]
testingData = statesTrim[-trainingRows, ]

reg_train = lm(GrowthRateInv ~ TotalEduSec + HHSize, data=trainingData)
summary(reg_train)

testingPred = predict(reg_train, newdata = testingData)

par(mfrow=c(1,2))

sqrt(mean((testingData$GrowthRateInv - testingPred)^2))



reg_train2 = lm(GrowthRate ~ TotalEduSec + HHSize, data=trainingData)
summary(reg_train2)

testingPred2 = predict(reg_train2, newdata = testingData)

plot(x=testingData$GrowthRate, y = testingPred2, xlim=c(10,50), ylim=c(10,50), xlab="Growth Rate Testing Data", ylab="Growth Rate Predicted Data", main = "Growth Rate", cex.lab=main_cex, cex.axis=main_cex, cex.main=main_cex, cex.sub=main_cex)
abline(0,1)


plot(x=testingData$GrowthRateInv, y = testingPred, xlim=c(0,7), ylim=c(0,7), xlab="Growth Rate Inv Testing Data", ylab= "Growth Rate Inv Predicted Data", main = "Growth Rate Inv", cex.lab=main_cex, cex.axis=main_cex, cex.main=main_cex, cex.sub=main_cex)
abline(0,1)


mtext("Out of Sample Validation", side = 3, line = -1, outer = TRUE)