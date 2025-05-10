import_results_combined2 <- function(path_combined) {
  
  
  dt_test <- path_combined |> 
    read_excel(.name_repair = "unique_quiet") |> 
    as.data.table()
  
  #  this works because handicap files were beingdownloaded as "Complete reults" rather than "for edit"...not ideal strategy
  race_format <- if(names(dt_test)[1] == "Bib") "waves" else {"handicapped"}

  
  if(race_format=="waves") {
    
    dt_combined <- dt_test[TRUE]
    
    dt_started <- dt_combined[!(Time %in% c("DNS","DNF"))]
    
    # setnames(dt_started,
    #          c("Lap 1","Lap 2","Lap 3"),
    #          c("swim","ride","run"))
    
    
    dt_started[,`:=`(`Split 1` = NULL,
                     `Split 2` = NULL,
                     `Split 3` = NULL)]
    
    dt_started[, Bib := as.character(Bib)]
    
    
    
  }
  
  
  if(race_format=="handicapped") {
    
    dt_combined <- path_combined |>
      read_excel(skip = 1, .name_repair = "unique_quiet") |> 
      as.data.table()
    
    dt_started <- dt_combined[!is.na(Place)][
      !(Place %in% c("Place"))][
        !(`Adjusted time` %in% c("DNS","DNF"))]
    
    names_expected <- names(dt_started)[8] == "Time" && 
      names(dt_started)[12] == "Handicap"
    
    if(!names_expected) stop("Unexpected column names in results file")
    
    # if(names(dt_started)[11]=="...11") browser()
    
    if(all(names(dt_started)[9:12]==c("Lap 1","Lap 2", "...11","Handicap"))) {
      names(dt_started)[11] <- "Lap 3"
    }
    
    # setnames(dt_started, names(dt_started)[9:11], c("swim","ride","run"))
    
    
    
    dt_started[, `:=` (Difference = NULL,
                       `% Back` = NULL,
                       `% Winning` = NULL,
                       `% Average` = NULL,
                       `% Median` = NULL)]
    
  }
  
  
  
  
  
  
  
  
  
  
  
  list(dt_started = list(dt_started),
       race_format = race_format)
  
  
  
  
  
  
}


if(FALSE) {
  path_combined <- "data_files/this_season/races/2023-09-23/3_INPUT_race_results/23 Sep 2023.xls"
}