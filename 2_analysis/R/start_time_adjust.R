# adjust_seconds - how many seconds to add or subtract to the first lap (and propagate changes to split and total times)
#                - if the race timer was started early this value will be negative
#                - if the race timer was started late  this value will be positive

start_time_adjust <- function(path_in, path_out, adjust_seconds) {
  
  if(missing(adjust_seconds)) stop("Need to provide number of seconds to adjust start time by")
  if(missing(path_in)) path_in <- file.choose()
  if(missing(path_out)) {
    
    adjust_seconds_display <- ifelse(adjust_seconds>0, paste0("+",adjust_seconds), as.character(adjust_seconds))
    
    path_out <- gsub("\\.xlsx$", paste0("_ADUSTED_", adjust_seconds_display,".xlsx"), path_in)
  }
  
  
  dt_in <- path_in |> 
    read.xlsx(sep.names = " ") |> 
    as.data.table()
  
  cols_to_adjust <- c(
    "Time",
    "Lap 1",
    paste0("Split ", 1:5)
  )
  
  cols_to_adjust <- cols_to_adjust[cols_to_adjust %in% names(dt_in)]
  
  
  # Adjustment --------------------------------------------------------------
  
  
  dt_adjust <- dt_in[Time %notin% c("DNS","DNF")]  
  
  dt_adjust[, (cols_to_adjust) := lapply(.SD, function(x) fifelse(x=="",NA,x)), .SDcols = cols_to_adjust]
  dt_adjust[, (cols_to_adjust) := lapply(.SD, hmsOrMsToSeconds), .SDcols = cols_to_adjust]
  
  dt_issues <- dt_adjust[, .(time_negative = any(lapply(.SD, function(x) x + adjust_seconds < 0 ))), .SDcols = cols_to_adjust, by = .I]
  if(nrow(dt_issues[(time_negative)])>0) {
    stop("Some total/split times to be adjusted are less than the time being deducted.")
  }
  
  dt_adjust[, (cols_to_adjust) := lapply(.SD, function(x) seconds_to_hms_simple(x + adjust_seconds)), .SDcols = cols_to_adjust]
  dt_adjust[, (cols_to_adjust) := lapply(.SD, function(x) fifelse(is.na(x),"",x)), .SDcols = cols_to_adjust]
  

# Export ------------------------------------------------------------------

  write.xlsx(dt_adjust, path_out)
}