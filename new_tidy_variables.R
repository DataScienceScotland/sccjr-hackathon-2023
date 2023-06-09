require(tidyverse)
require(haven)
library(sjlabelled)

setwd(project_path)

#### Read in SPSS datasets ####

# Non-victim form (NVF)
df_0809 <- read_spss("./data/scjs_s2_rf_091214.sav")
df_0910 <- read_spss("./data/scjs_s3_rf_ukda_110120.sav")
df_1011 <- read_spss("./data/scjs_s4_2010-11_rf_ukda_130115.sav")
df_1213 <- read_spss("./data/scjs_main_2012_13_5.sav")
df_1415 <- read_spss("./data/new_main_2014_15_2_main_dataset.sav")
df_1617 <- read_spss("./data/scjs1617_nvf-main_y1_eul.sav")
df_1718 <- read_spss("./data/scjs1718__nvf-main_y2_eul_20190508.sav")
df_1819 <- read_spss("./data/scjs1819_nvf-main_y3_eul-safeguarded_20210316_nvf.sav")
df_1819_cyber <- read_spss("./data/scjs1819_nvf-main_y3_eul-safeguarded_20210316_cyber.sav")
df_1920 <- read_spss("./data/scjs1920_nvf-main_y4_eul-safeguarded_20210322_nvf.sav")
df_1920_cyber <- read_spss("./data/scjs1920_nvf-main_y4_eul-safeguarded_20210322_cyber.sav")

# merge cyber on to 1819 and 1920 data with natural join
df_1819 <- left_join(df_1819, df_1819_cyber)
df_1920 <- left_join(df_1920, df_1920_cyber)

# Self-completion data (SC)
df_0809_sc <- read_spss("./data/scjs2_sc_091209.sav")
df_0910_sc <- read_spss("./data/scjs_s3_scf_110808.sav")
df_1011_sc <- read_spss("./data/scjs_s4_2010-11_sc_ukda_130115.sav")


combined_data <- 
  tibble(
    year = c("2008_09",
             "2009_10",
             "2010_11",
             "2012_13",
             "2014_15",
             "2016_17",
             "2017_18",
             "2018_19",
             "2019_20"),
    data = list(
      
      df_0809,
      df_0910,
      df_1011,
      df_1213,
      df_1415,
      df_1617,
      df_1718,
      df_1819,
      df_1920
      
    )
  )

rm(list = c("df_1819_cyber", "df_1920_cyber"))

vars_to_keep <- c("serial|case|wgtg|prev|qpolconf|qs2area|qsfdark|qsfnigh|qratpol|polop|compol|polpres|qworr|numcar|qaco_|lcpeop|qhworr|qswem|dconf|pcon")
broken_vars <- c("nummot|polpatr")

### Functions
df_names_lower <- function(df, srv_year){
  df %>% rename_all(., .funs = tolower)
}

add_scjs_ids <- function(df, srv_year){
  
  if("serial2" %in% colnames(df)) {
    df <- 
      df %>% 
      rename(serial = serial2)
  }
  
  df %>% 
    mutate(case_id = str_pad(serial, 
                             width = 10, # this is the maximum size of the case_id variable across all datsets
                             side = "left",
                             pad = "0"),
           survey_year = srv_year,
           year_case_id = paste(survey_year, case_id, sep = "-")) %>% 
    select(serial, case_id, survey_year,year_case_id, everything())
  
}

extract_name_data <- function(df, srv_year){
  df <- df[,grepl(vars_to_keep,names(df))]
}

### Apply functions

scjs_combined <- 
  combined_data %>% 
  mutate(data = map2(data, year, df_names_lower)) %>% 
  mutate(data = map2(data, year, add_scjs_ids)) %>% 
  mutate(data = map2(data, year, subset_vars)) %>% 
  unnest_legacy()


### Testing if data looks ok

scjs_combined %>% select(year, wgtgindiv) %>% 
  group_by(year) %>% 
  summarise(sum(wgtgindiv))

scjs_combined %>% select(year, prevviolent, wgtgindiv) %>% 
  group_by(year, prevviolent) %>% 
  summarise(sum(wgtgindiv))

scjs_combined %>% select(year, prevsurveycrime, wgtgindiv) %>% 
  group_by(year, prevsurveycrime) %>% 
  summarise(sum(wgtgindiv))



##############

df_test <- df_0809 %>% select(nummot)
"QS2AREAS" %in% names(df_1920)
"numcar" %in% names(df_1213)

vars_to_keep2 <- c("serial|case|wgtg|prev|qpolconf|qs2area|qsfdark|qsfnigh|qratpol|polop|compol|polpres|qworr|numcar|qaco_|lcpeop|qhworr|qswem|dconf|pcon|nummot|polpatr")
broken_vars <- c("nummot|polpatr")



df_0809_test <- df_0809[,grepl(vars_to_keep2,names(df_0809))]
df_0910_test <- df_0910[,grepl(vars_to_keep2,names(df_0910))]
df_1011_test <- df_1011[,grepl(vars_to_keep2,names(df_1011))]
df_1213_test <- df_1213[,grepl(vars_to_keep2,names(df_1213))]
df_1415_test <- df_1415[,grepl(vars_to_keep2,names(df_1415))]
df_1617_test <- df_1617[,grepl(vars_to_keep2,names(df_1617))]
df_1718_test <- df_1718[,grepl(vars_to_keep2,names(df_1718))]
df_1819_test <- df_1819[,grepl(vars_to_keep2,names(df_1819))]
df_1920_test <- df_1920[,grepl(vars_to_keep2,names(df_1920))]

scjs_combined2 <- scjs_combined %>% select(year, qs2area) %>% filter(year == "2019_20")
names(scjs_combined)

subset_vars <- function(df, srv_year){
  df %>% select(serial, case_id, survey_year,year_case_id,
                starts_with(c("wgtg", #weighting
                            "prev", #prevalence
                            "qs2area", #crime rate
                            "qsfdark", #feeling of safety
                            "qsfnigh", #feeling of safety
                            "qworr", #worry of victimisation
                            "qhapp", #perceived likelihood of victimisation
                            "qdconf",
                            "qpolconf",
                            "polpatr",
                            "polpres",
                            "polop",
                            "qpcon",
                            # "cyber",
                            "qwall",
                            "lcpeop",
                            "qaco"
                            ))
                )
}


################

rowsum_partialstringmatch_variables<-function(df,partial,full){
  df %>% dplyr::select(contains(partial)) %>% names() -> allnames
  #these are all the variables which have an equivalent variable but with a 0
  allnames[sapply(seq_along(allnames),
                  function(x) any(grepl(gsub(partial,full,allnames[x]),allnames[-x]))
  )] -> mismatchnames
  
  for (i in gsub(partial,full,mismatchnames)){
    df[,i]<-rowSums_na(cbind(df[,i],df[,gsub(full,partial,i)]))
  }
  cat("these variables",mismatchnames,"have been collapsed into",gsub(partial,full,mismatchnames),sep=" ")
  return(df %>% dplyr::select(-one_of(mismatchnames)))
}




scjs_combined %>% group_by(year) %>% summarise_all(
  ~ sum(!is.na(.))) %>%
  gather(., key="variable",value="number_obs",-year) -> year_counts

year_counts %>% group_by(variable) %>% 
  summarise(
    no_na = !(any(number_obs==0))
  ) -> variable_across_years
