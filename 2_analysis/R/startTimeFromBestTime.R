startTimeFromBestTime <- function(x, seconds_finish = 27000) {
  
  out <- character(length(x))
  
  ind_is_finite <- is.finite(x)
  
  out[ind_is_finite] <-  seconds_to_hms_simple(seconds_finish - x[ind_is_finite])
  out[x>5400] <-   "6:00:00"

  out
}