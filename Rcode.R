# Install and Load All Packages required to run this analysis
pacman::p_load(dplyr,naniar,MASS,corrplot,randomForest,mlr, plm,ivpack, MatchIt,data.table,optmatch,ggplot2)


#Loading Treatment and Control Datasets
treat<-read.csv('Treatment.csv',sep=',',stringsAsFactors=F)
control<-read.csv('Control.csv',sep=',',stringsAsFactors=F)

# Clubbing the Datasets int0 One
treat$treat <- c(1)
control$treat <-c(0)

col.names <- c("TimeStamp","Gender","Age","Income","Occupation","Region","AppUsage","OrderFrequency","OfferOrder","LikePicture","PhotoSales","PhotoStyle","Temptation","Order","Cinemagraph","Interact","Treat")

colnames(treat) <-col.names
colnames(control) <- col.names

data <- rbind(treat,control)

data$SrNo <- c(1:nrow(data))
data <- data[, c(1,18,2:17)]

# Data Pre-Processing 
data$Interact[data$Interact==""] <- "Yes"
data %>% replace_with_na(replace = list(OrderFrequency = "", OfferOrder="")) -> data

data$Age[data$Age=="21 - 30 years" | data$Age=="21-30 years"] <- "21-30 years"
data$Age[data$Age=="31 - 40 years" | data$Age=="31-40 years"] <- "31-40 years"
data$Age[data$Age=="41 - 50 years" | data$Age=="41-50 years"] <- "41-50 years"
data$Age[data$Age=="More than 50 years" | data$Age=="More than 51"] <- "More than 50 years"

data$Income[data$Income == "Less than $10k"] <- "Less than $10K"

data$Occupation[data$Occupation == "Employed - Full time"] <- "Employed-Full Time"
data$Occupation[data$Occupation == "Employed - Part time"] <- "Employed-Part Time"

data$OrderFrequency[data$OrderFrequency == "Ocassionally" | data$OrderFrequency == "Occasionally"] <- "Occasionally"

data$OrderFrequency <- as.character(data$OrderFrequency)
data$OrderFrequency[is.na(data$OrderFrequency)] <- "Never"

data$OfferOrder <- as.character(data$OfferOrder)
data$OfferOrder[is.na(data$OfferOrder)] <- "No"

#Changing Order Variable
#data$OrderCat <- data$Order[ifelse((data$Order==4 | data$Order==5),1,0)]
data$OrderCat <- ifelse(data$Order %in% c(4,5),1,0)

#Changing the Temptation Varaible
data$TemptationCat[data$Temptation %in% c(8:10)] <- "High"
data$TemptationCat[data$Temptation %in% c(5:7)] <- "Medium"
data$TemptationCat[data$Temptation %in% c(1:4)] <- "Low"


data[,c(3:17,19:20)] <- lapply(data[,c(3:17,19:20)], factor)

#Displaying Summary of the merged data
summary(data)

####################################################################

# EXPLORATORY DATA ANALYSIS

# 1) Pie Charts
#We can see various Age groups and occupations of the users who participated in this survey.
age <- lapply(data[, c("Age","Occupation")], table)
age1<-data.table(age$Age)
colnames(age1) <- c("AgeGroup","Count")

bp<- ggplot(age1, aes(x="", y=Count, fill=AgeGroup))+
  geom_bar(width = 1, stat = "identity")

pie <- bp + coord_polar("y", start=0)

blank_theme <- theme_minimal()+
  theme(
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    panel.border = element_blank(),
    panel.grid=element_blank(),
    axis.ticks = element_blank(),
    plot.title=element_text(size=14, face="bold")
  )

pie + blank_theme +
  theme(axis.text.x=element_blank())

# 
occp <- lapply(data[, c("Age","Occupation")], table)
occp1<-data.table(age$Occupation)
colnames(occp1) <- c("Occupation","Count")

bp1<- ggplot(occp1, aes(x="", y=Count, fill=Occupation))+
  geom_bar(width = 1, stat = "identity")

pie1 <- bp1 + coord_polar("y", start=0)

pie1 + blank_theme +
  theme(axis.text.x=element_blank())


# Plot temptations proportions
#Here we can see the Proportion of Temptation Levels in both control and treatment groups. 
#We can clearly see that Gifs have induces more hunger temptation levels when compared to the food pictures.
temp1 <- data %>% 
  group_by(Temptation, Treat) %>%
  summarize(count = n())
temp1 <- temp1 %>% group_by(Treat) %>%
  mutate(percentage = count / sum(count))

ggplot(data = temp1, mapping = aes(x=Temptation,y=percentage, fill=Treat)) +
  geom_col() + 
  facet_wrap(vars(Treat)) +
  theme(legend.position = "none") +
  labs(x="Temptation Levels", y="Percentage")


# Box Plot 1
#Box Plot Showing the Relation Between Order Likelihood and Temptation
ggplot(data, aes(x = Order, y = as.numeric(Temptation))) +
  geom_boxplot(size = .75, color="blue4") +
  geom_jitter(alpha = .3, color = "sienna4") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1))  + 
  labs(title="Box Plot Showing the Relation Between Order Likelihood and Temptation") + 
  ylab("Temptation") 

#Order Likelihood Vs Temptation in Control and Treatment Groups
ggplot(data, aes(x = Order, y = as.numeric(Temptation))) +
  geom_boxplot(size = .75, color="blue4") +
  geom_jitter(alpha = .4, color = "seagreen4") +
  facet_wrap(vars(Treat)) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1)) + 
  labs(title="Order Likelihood Vs Temptation in Control and Treatment Groups") + 
  ylab("Temptation") 

#Photostyle
ggplot(data, aes(x = PhotoStyle, y = as.numeric(Order))) +
  geom_boxplot(size = .75, color="red4") +
  geom_jitter(alpha = .3, color = "gray3") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1))  + 
  labs(title="Box Plot Showing the Relation Between Order Likelihood and Temptation") + 
  ylab("Order Likelihood") + xlab("Photography Style")

photo <- lapply(data[, c("PhotoStyle","Cinemagraph")], table)
photo1<-data.table(photo$PhotoStyle)
colnames(photo1) <- c("PhotographyStyle","Count")

ggplot(photo1, aes(x = PhotographyStyle, y= Count, color=PhotographyStyle)) +
  geom_bar(stat="identity", fill="white")

#Similar trend in treatment and Control
ggplot(data) +
  aes(x = PhotoStyle, colour = Treat) +
  geom_bar(fill = "#0c4c8a") +
  scale_color_distiller(palette = "PuOr") +
  theme_linedraw() +
  facet_wrap(vars(Treat))

# Like Picture
ggplot(data, aes(x = LikePicture, y = as.numeric(Temptation))) +
  geom_boxplot(size = .75, color="blue4") +
  geom_jitter(alpha = .4, color = "seagreen4") +
  facet_wrap(vars(Treat)) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1)) + 
  labs(title="Temptation Level Vs Like Pictures in Control and Treatment Groups") + 
  ylab("Temptation") 

####################################################################

# PROPENSITY SCORE MATCHING
set.seed(123)
data1 <- data.table(data)
Match <- matchit(Treat ~ Age + Income + Region + LikePicture + PhotoStyle + OrderFrequency, data = data1, method = 'optimal')

MyDataSummary.match <- data.table(match.data(Match))
Matched.ids <- data1$SrNo %in% MyDataSummary.match$SrNo
data1 <- data1[, match := Matched.ids]

summary(Match)

# T-tests before Matching
#For Order Likelihood difference in means
t.test(as.numeric(Order) ~ Treat, data = data)
#For Temptation Level difference in means
t.test(as.numeric(Temptation) ~ Treat, data = data)

# T-tests Post Matching
data2 <- data1[match == TRUE]
#For Order Likelihood difference in means
t.test(as.numeric(Order) ~ Treat, data = data2)
#For Temptation Level difference in means
t.test(as.numeric(Temptation) ~ Treat, data = data2)



#ORDERED MULTINOMIAL LOGIT REGRESSION

#Temptation Model
multi.model <- polr(Temptation ~ Treat + Age + PhotoStyle + LikePicture + Cinemagraph , data = data1[match == TRUE], Hess=T)
summary(multi.model)

# Converting the estimate results into less complex form by taking exponential of the estimate values
interpret1<-as.data.frame(exp(coef(multi.model)))
colnames(interpret1) <- c("Estimate")
interpret1

# Order Model
multi.model1 <- polr(Order ~ Treat + OfferOrder + PhotoSales  + Income  , data = data1[match == TRUE], Hess=T)#
summary(multi.model1)

#Converting the estimate results into less complex form by taking exponential of the estimate values
interpret2<-as.data.frame(exp(coef(multi.model1)))
colnames(interpret2) <- c("Estimate")
interpret2









