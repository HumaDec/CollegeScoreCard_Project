library(dplyr)
library(ggplot2)
library(readr)
library(ggridges)

library(ggplotify)
library(gridExtra)
library(forcats)
library(viridis)

# install.packages('visdat')
library(visdat)

setwd('/Users/yuhanburgess/Documents/GitHub/DataMungingProject2')
df <- read_csv("csv_files/MERGED2021_22_PP.csv")

######################################################################################
# INITIAL FILTERING

df_filter <- function(df) {
  # changing all NULL values into NA values
  df<-df %>%
    mutate_all(~ifelse(. == "NULL", NA, .))
  
  # vis_miss(df, warn_large_data = FALSE)
  
  df_test <- df[1:6049,] # removing bottom rows since they do not contain important info for analysis
  # vis_miss(df_test, warn_large_data = FALSE) # plotting missing and present data in csv file
  
  # remove columns that are not 70% complete
  names <-apply(df_test, 2, function(x) sum(!is.na(x))/length(x) > 0.70)
  df<- as.data.frame(df)
  df<-df[, c(names)]
   
  df <- df_categorical(df) # change three columns from numeric to categorical data
  
  # vis_miss(df1, warn_large_data = FALSE)
  
  return(df)
  
}

# categorizing columns Highest degree, Predominant degree, and 
# Carnegie classification columns
df_categorical <- function(df){
  pred_deg_awarded <- c('Not classified', 'Certificate', 
                        'Associate', 'Bachelor', 
                        'Graduate')
  
  high_deg_awarded <- c('Non-degree', 'Certificate', 
                        'Associate', 'Bachelor', 
                        'Graduate')
  
  cc_basic_score <- c('Associate: High Transfer-High Traditional', 'Associate: High Transfer-Mixed Traditional/nontraditional',
                      'Associate: High Transfer-High Nontraditional', 'Associate: Mixed Transfer/Career & Technical-High Traditional',
                      'Associate: Mixed Transfer/Career & Technical-Mixed Traditional/Nontraditional','Associate: Mixed Transfer/Career & Technical-High Nontraditional',
                      'Associate: High Career and Technical- High Traditional','Associate: High Career and Technical-Mixed Traditional/Nontraditional',
                      'Associate: High Career and Technical-High Nontraditional', 'Special Focus 2-Years- Health Professions',
                      'Special Focus 2-Years: Technical Professions','Special Focus 2-Years: Arts and Design',
                      'Special Focus 2-Years: Other Fields','Baccalaureate/Associate Colleges: Associate Dominate',
                      'Doctoral Universities: Very High Research Activity','Doctoral Universities: High Research Activity',
                      'Doctoral/Professional Universities','Masters Colleges and Universities: Larger Programs',
                      'Masters Colleges and Universities: Medium Programs', 'Master Colleges and Universities: Small Programs',
                      'Baccalaureate Colleges: Arts and Science Focus','Baccalaureate Colleges: Diverse Fields','Mixed Baccalaureate/ Associates',
                      'Special Focus 4-Years: Faith-Related Institutions','Special Focus 4-Years: Medical Schools and Centers',
                      'Special Focus 4-Years: Other Health Profession Schools','Special Focus 4-Years: Engineering Schools',
                      'Special Focus 4-Years: Other Related-Technology Related Schools','Special Focus 4-Years: Business and Management Schools',
                      'Special Focus 4-Years: Arts, Music, and Design School','Special Focus 4-Years: Law Schools',
                      'Special Focus 4-Years: Other Special Focus Institutions','Tribal Colleges')
  
  
  # changes numeric values to categorical
  valid_indx <- which (df$CCBASIC != -2) # -2 is not associated to a numeric value (not changing the value)
  df$CCBASIC[valid_indx] <- cc_basic_score [as.numeric(df$CCBASIC[valid_indx])+1]
  df$HIGHDEG <- high_deg_awarded[as.numeric(df$HIGHDEG)+1]
  df$PREDDEG <- pred_deg_awarded[as.numeric(df$PREDDEG)+1]
  
  return(df)
}

# further trimming of dataframe to be used in some anaylsis
df_shorten <- function(df){
  df <- df[, 1:450] 
  #REMOVING ROWS THAT ARE 90% INCOMPLETE 
  # Calculate the percentage of NA values for each row
  row_na_percent <- rowSums(is.na(df)) / ncol(df) * 100
  # Find rows with 90% or more NA values
  rows_with_90_percent_or_more_na <- which(row_na_percent >= 90)
  
  # MAY REMOVE LATER
  na_df <- df %>%
    filter(row_number() %in% rows_with_90_percent_or_more_na)
  
  # returns df that have rows that are less than 90% incomplete
  filtered_df <- df %>%
    filter(!(row_number() %in% rows_with_90_percent_or_more_na))
  
  
 return(filtered_df) 

}

# function filters out data that does not 
# contain actual states 

# this may not be needed since there is a built in state.abb that we use later on
# but I am too pressed for time right now to change it
state_isolation <- function (df){
  # list of only states 
  states <- c('AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 
              'CT', 'DE', 'FL', 'GA', 'HI', 'ID', 
              'IL', 'IN', 'IA', 'KS', 'KY', 'LA',
              'ME', 'MD', 'MA', 'MI', 'MN', 'MS', 
              'MO', 'MT', 'NE', 'NV', 'NH', 'NJ', 
              'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 
              'OR', 'PA', 'RI', 'SC', 'SD', 'TN', 
              'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 
              'WI', 'WY')
  
  # remove any territories of the US that are not considered states 
  filtered_df <- df%>%
    filter(STABBR %in% states)
  
  return(filtered_df)
}

# function filters data set to be used in 
# bar_plot function
instit_operations <- function(df){
  filtered_df <- state_isolation(df)
  
  state_count <- filtered_df %>%
    count(STABBR)

  open_instit <- filtered_df%>%
    filter(CURROPER == 1)%>%
    count(STABBR)

  closed_instit <- filtered_df%>%
    filter(CURROPER == 0)%>%
    count(STABBR)
  
  # if you want to return more than one thing, you have to return a list 
  return(list(state_count = state_count, open_instit = open_instit, closed_instit= closed_instit))
}

# function filters data set to be used in 
# group_bar_plot function
group_bar_filter <- function(df){
  # retrieving two columns 
  state_class <- filtered_df[c('STABBR', 'PREDDEG')]

  # count occurrences based on the degree and which state it is from
  unique_combo <- state_class%>%
    group_by(STABBR, state_class[2])%>%
    summarise(UniqueCount = n())
  
  # check to make sure we are only looking at states
  unique_combo <- state_isolation(unique_combo)
  
  # create a new column of z-scores just in case
  # never actually used but oh well (just using up memory)
  unique_combo$zscore <- scale(unique_combo$UniqueCount)[,1] # normalizing calculations using z-score
  
  return(unique_combo)
}

# function filters data set to be used in 
# ridge_plot function
ridge_plot_filter <- function(df){
  demograph <-df[,264:273]  # retrieving information about student demographic
  pred_undergrad <- cbind(STABBR = df [,6], df[,14:15], CCBASIC = df[,22])# retrieving principal information about institution
  
  # this analysis looks specifically at special focus 4-year institutions and those that are considered baccalaureate
  # when I wrote bach_stud I thought (Bach is a stud)
  bach_stud <- cbind(pred_undergrad,demograph)
  return(bach_stud)
}


# function filters data set to be used in 
# exp_vs_profit_plot function
exp_vs_profit_filter <- function(df, colname){
  # df that contains (State, predominate degree, highest degree, Carnegie classification, 
  #tuition revenue, and instructional expenses)
  finance_df <- cbind(STABBR = df[,6], df[,14:15], CCBASIC = df[,22], df[,275:276])
  
  # getting the mean of all tuition revenue for each classification within each state
  tuition_rev_df <- finance_df%>%
    group_by(STABBR, !!sym(colname))%>% # !!sym() = bang bang operator unquotes the variable name
    summarise(state_tuition_rev_mean = mean(as.numeric(TUITFTE), na.rm = TRUE))
  
  # getting the mean of all instructional expenses for each classification within each state
  expense_df <- finance_df%>%
    group_by(STABBR, !!sym(colname))%>%
    summarise(state_expense_mean = mean(as.numeric(INEXPFTE), na.rm = TRUE))
  
  # merging the information into one df
  exp_vs_profit_df  <- cbind(tuition_rev_df, expense_df[,3])
  
  # finding the difference between the revenue and expenses
  exp_vs_profit_df <- exp_vs_profit_df%>%
    mutate(difference = state_tuition_rev_mean- state_expense_mean)
  return(exp_vs_profit_df)
}

df_trimmed<- df_filter(df)
filtered_df <-df_shorten(df_trimmed)
institut_ops <- instit_operations(filtered_df)
group_plot_filtered_df<-group_bar_filter(filtered_df)
ridge_plot_df <- ridge_plot_filter(filtered_df)

######################################################################################
# grouped_bar plot of instructional expenditure per full-time student (INEXPFTE)and net tuition 
# revenue per full-time student (TUITFTE)
graphics.off() 


# finance_plot <- function(df){
#   plot <- ggplot(df, aes(x = STABBR, group = PREDDEG))+
#     geom_bar(aes(y = state_tuition_rev_mean, fill = 'tuition revenue'), stat = 'identity', position = 'dodge' , width = 0.5)+
#     geom_bar(aes(y = state_expense_mean, fill = 'instructional expense'), stat ='identity', position = 'dodge', width = 0.4)+
#     scale_fill_manual(values = c('tuition revenue' = 'blue', 'instructional expense' = 'darkorange'))+
#   labs(
#       title = 'Mean Tuition Revenue vs Mean Instruct. Expense Per Full-Time Equivalent Student',
#       x = 'State',
#       y = 'Mean Value',
#       fill = 'Category'
#     )+
#     theme(axis.title.x = element_text(size = 6, angle = 90))+
#     theme_classic()
#   print(plot)
#   return(plot)
# }

# create a barplot of the z_core difference of the difference between the mean tuition 
# revenue and institutional expences per state

z_finance_plot <- function(df, fill, colname){
  plot <- ggplot(df, aes(x = STABBR, group = !!sym(colname)))+
    geom_bar(aes(y = !!sym(colname), # z-score value
                 fill = !!sym(fill)), # coloring the bars based on PREDDEG, HIGHDEG, CCBASIC
             stat = 'identity', 
             position = 'dodge', # positions the bars next to each other instead of on top of each other
             width = 0.5)+
    scale_fill_viridis(discrete = TRUE, 
                       option = 'viridis', 
                       direction = -1)+
    labs(
      title = 'Mean Tuition Revenue vs Mean Instruct. Expense Per Full-Time Equivalent Student',
      x = 'State',
      y = 'z-score of difference between tuition revenue and instruction expenses',
      fill = 'Category'
    )+
    theme_classic()
  
  # plot <- plot + theme(legend.position = 'none')
  print(plot)
  return(plot)
}

# create a multiple of the z_core difference of the difference between the mean tuition 
# revenue and institutional expenses per state and separating each graph based on state
z_finance_subplot <- function(df, fill, colname, filename){
  plots <- lapply(unique(df$STABBR), function(state) {
    
    # uses built-in state.abb to group graph based on state 
    data_subset <- subset(df, STABBR == state) 
    
    # calling z_fiance_plot to get each subplot
    subplot <- z_finance_plot(data_subset, fill, colname)
    return(subplot)
  }) # end apply
  
  # saving plots into a PDF file
  pdf(filename)  # Output to a PDF file
  for (i in 1:length(plots)) {
    print(plots[[i]])
  }
  dev.off()  # Close PDF device
  
  return(plots)
  
} 

df_trimmed <- df_trimmed%>%
  filter(CURROPER == 1)

df_trimmed <- state_isolation(df_trimmed)

# sorry for the repeat, I know this could be in a loop- but here we are
# getting difference based on grouping of preddeg
preddeg_exp_vs_profit_df <- exp_vs_profit_filter(df_trimmed, 'PREDDEG')
preddeg_exp_vs_profit_df$zscore <- scale(preddeg_exp_vs_profit_df$difference)[,1] # normalizing calculations using z-score

preddeg_exp_vs_profit_plot <- z_finance_plot(preddeg_exp_vs_profit_df, 'PREDDEG', 'zscore')
preddeg_exp_vs_profit_subplot <- z_finance_subplot(preddeg_exp_vs_profit_df, 'PREDDEG', 'zscore', 'z_pred_finance_plots.pdf')


# getting difference based on grouping of HIGHDEG
highdeg_exp_vs_profit_df <- exp_vs_profit_filter(df_trimmed, 'HIGHDEG')%>%
  filter(HIGHDEG != 'Non-degree')
highdeg_exp_vs_profit_df$zscore <- scale(highdeg_exp_vs_profit_df$difference)[,1] # normalizing calculations using z-score

highdeg_exp_vs_profit_plot <- z_finance_plot(highdeg_exp_vs_profit_df, 'HIGHDEG', 'zscore')
# highdeg_exp_vs_profit_subplot <- z_finance_subplot(highdeg_exp_vs_profit_df, 'HIGHDEG', 'zscore', 'z_high_finance_plots.pdf')


# getting difference based on grouping of CCBASIC
ccbasic_exp_vs_profit_df <- exp_vs_profit_filter(df_trimmed, 'CCBASIC')
ccbasic_exp_vs_profit_df$zscore <- scale(ccbasic_exp_vs_profit_df$difference)[,1] # normalizing calculations using z-score
ccbasic_exp_vs_profit_subplot <- z_finance_subplot(ccbasic_exp_vs_profit_df, 'CCBASIC', 'zscore', 'z_ccbasic_finance_plots.pdf')

## ANALYSIS
# The bars in the negative means the instructional expenses are greater than the tuition revenue
# this could indicate that they are wanting to spend more towards delivering educational services.
# Based on the graphs, it looks like, Associate degree institutions spend more on instructional 
# expenditures then receiving tuition revenue. 

# Some factors that could play into this
# 1. a majority of associate programs could be public which means they will more likely be funded by
# the government
# 2. the expenses to get an AA is cheaper than a different type of degree so tuition prices may have a
# lower threshold

# Looking at the HIGHDEG filtering on tuition revenue and instruction expenditure, Certificate programs look to 
# to have higher revenue in comparison to instruction expenses.
# 
# Some factors that could play into this
# 1. Certificate programs could be online
# 2. The time frame to complete it is not as long
# 3. There is not as much upfront cost to get certain materials (for example in a chemistry lab and 
# the need to get ppe,chemicals, etc.)


## Unkwn Variables
# Does financial aid/ pell grant recipient alter the revenue cost? If so then more people who get these
# may mean the institution get more federal money from their enrollment.
######################################################################################

# creating a barplot that looks at the number of institutions in each state 
bar_plot <- function(df) {
  titles <- c('Total Institutes', 'Open Institutes', 'Closed Institutes') # main title 
  ops_plots <- list() # list of 3 different graphs 
  
  # looking thorough total, open, and closed institution's df
  for (ops in 1:length(df)) {
    data <- df[[ops]] # getting index from list
    title <- titles[ops] # retrieving associated title
    
    # order the bars in descending order
    data <- data %>%
      mutate(STABBR = fct_reorder(STABBR, n))
    
    ops_plot <- ggplot(data, aes(x = STABBR, y = n, fill = n)) +
      geom_bar(stat = 'identity', # determines how the data should be summarized (height based on value of dataset)
               alpha = 0.7, 
               width = 0.5) +
      coord_flip() +
      scale_fill_viridis(discrete = FALSE, # coloring system is continuous 
                         option = 'viridis', # color palette used
                         direction = -1)+ # direction refers to the gradient direction
      xlab('') +
      ggtitle(title) +
      theme_classic() # background color of window
    
    ops_plots[[ops]] <- ops_plot # adding plot to a list 
  }
  
  # Combine the plots into one
  combined_plots <- grid.arrange(grobs = ops_plots, ncol = length(ops_plots))
  # Return the combined plot
  return(combined_plots)
}

# Call the bar_plot function
combined_plot <- bar_plot(institut_ops)

######################################################################################
# creating a bar plot that looks at the frequency of predominate degree 
# within each state and returns a pdf file that contains a graph of each state
group_bar_plot <- function(df) {
  plots <- lapply(unique(df$STABBR), function(state) {
    
    # uses built-in state.abb to group graph based on state 
    data_subset <- subset(df, STABBR == state) 
    
    cc_dist <- ggplot(data_subset, aes(x = STABBR, y = UniqueCount, fill = PREDDEG)) +
      geom_bar(stat = 'identity', 
               alpha = 0.7, # transparency of bars
               width = 0.5, # bar width
               position = 'dodge') + # each distinct bar is positioned next to each other
      facet_wrap(~STABBR, nrow = 10) +
      scale_fill_viridis(discrete = TRUE, 
                         option = 'viridis', # color palette being used in viridis library
                         direction = 1)+ # direction of gradient color
      # setting parameters for y-axis 
      scale_y_continuous(name = 'Predominate Degree', # y title
                         limits = c(0, 300), # the min and max of y-axis
                         breaks = seq(0,300, by = 25))+ # the incrementation markers of y-axis
      xlab('') + 
      theme_classic()+
      theme(legend.text = element_text(size = 6), # font text of variables in legend
            legend.position = 'right', # 
            axis.text.x = element_blank(),
            strip.text = element_text(size = 8))# the text on top of each graph
    
    return(cc_dist)
  })
  
  pdf("preddeg_per_state_plots.pdf")  # Output to a PDF file
  for (i in 1:length(plots)) {
    print(plots[[i]])
  }
  dev.off()  # Close PDF device
  
  return(plots)
  
}

# Call the group_bar_plot function
preddeg_plots <- group_bar_plot(group_plot_filtered_df)

######################################################################################
# Function to create ridge plots for different demographic variables 
# within each PREDDEG group and returns a pdf of all the graphs
ridge_plots <- function(df) {
  dem_group <-colnames(df[,5:13]) # getting the column names of the demographics that are listed 
  plots <- lapply(dem_group, function(dem) { # looking at groupings of plots based on demographic index
    ggplot(df, aes(x = as.numeric(.data[[dem]]), y = PREDDEG, fill = PREDDEG)) +
      geom_density_ridges() +
      scale_fill_viridis(discrete = TRUE, 
                         option = 'viridis', 
                         direction = -1) +
      theme_ridges() +
      scale_x_continuous(limits = c(0, 1)) + # set limits to range of data
      labs(title = dem) +  # Set the title for the plot
      theme(legend.position = 'right', # position of legend
            text = element_text(size = 8)) + # size of words in legend
      theme(axis.text.y = element_blank(),  # removing any x or y axis labels
            axis.title.y = element_blank(),
            axis.text.x = element_blank(), 
            axis.title.x = element_blank())
      
  })
  
  # Save each set of density plots to separate PDF files
  pdf('demographic_plots.pdf')
  for (i in 1:length(plots)) {
      print(plots[[i]])
    }
  dev.off()
  
  return(plots)
}

# Call the ridge_plots function
dem_ridge_plots <- ridge_plots(ridge_plot_df)

## ANALYSIS 
# Those who identify as white have a more balanced distribution withing all 
# the categories except graduate. There could be an association between access
# to higher education and identifying as white.

# There is a lower density of individuals who identity as another race who seek
# higher education (there is a predominate right skew to all the graphs)

# Lurking variable: population size of each demographic

######################################################################################
# Function creates a heatmap that visually represents the correlation 
# between the degree awarded and its Carnegie classification
heat_map <- function(df){
  # color palette can be found at here: 
  # https://r-graph-gallery.com/38-rcolorbrewers-palettes.html
  my_color_palette <- viridis_pal(alpha = 0.7, 
                                  direction = 1,
                                  option = 'viridis')(34)# Color palette, # number = # of colors
  heatmap_data <- as.matrix(df) # making sure data is in format that will return an image 
  # displaying heatmap between Carnegie classification and the highest degree offered
  map <- heatmap(heatmap_data, 
          Rowv = NA, # Do not cluster rows 
          Colv = NA, # Do not cluster columns 
          col = my_color_palette, 
          scale = "column", # Scale by column 
          main = "Carnegie classification vs. Degree", # title of heatmap
          cexCol = 0.8) # changing the text size of the degrees offered 

  return(map)
}

# df for heatmap
highest_heatmap_data <- table(filtered_df$CCBASIC, filtered_df$HIGHDEG)
predominate_heatmap_data <- table(filtered_df$CCBASIC, filtered_df$PREDDEG)

# calls heat_map function
highestvsCCBASIC <- heat_map(highest_heatmap_data)
predominatevsCCBASIC <- heat_map(predominate_heatmap_data)

## ANALYSIS
# general: -2 looks to be referring to institutions that are certificate
# or non-degree grant. Both also have a similar correlation between CCBASIC
# scores listed as Associate or Special Focus 2-Years and associate degree
# awarded. 

# CCBASIC vs HIGHDEG
# Intuitively, there is a better correlation between the CC classification and
# highest degree awarded. We can see this in the Graduate column where a majority 
# of the lighter colors are associated with masters and doctoral programs. We can 
# see a similar grouping of Special Focus 4-Year institutions and baccalaureate 
# institutions with the Bachelor degree. (I would expect institutions that say 4-years
# are working towards a bachelor's degree.)

# CCBASIC vs PREDDEG
# In this map we can see that Bachelor degree has a higher correlation with 
# baccalaureate, masters, and doctoral institutions. This could be because
# individuals are only looking at getting bachelors, but the institution that they
# go to allows for further studies. 

