#' This function takes a row of split times (including start time)
#' and calculates the laps and total times


lapsAndTotalFromSplitsCopyExcel <- function(splits_excel_copy) {
  
  stopifnot(length(splits_excel_copy)==1)
  
  splits_vector <- strsplit(splits_excel_copy, "\t")[[1]]
  
  return(
    list(
      laps = 
        
        splits_vector |> 
        hmsOrMsToSeconds() |> 
        diff() |> 
        seconds_to_hms_simple()
      ,
      
      # total
      total = splits_vector[c(1, length(splits_vector))] |> 
        hmsOrMsToSeconds() |> 
        diff() |> 
        seconds_to_hms_simple()
    )
  )
  
}
if(FALSE) {
  lapsAndTotalFromSplitsCopyExcel("0:14:09	0:26:12	1:05:00	1:30:00")
}

