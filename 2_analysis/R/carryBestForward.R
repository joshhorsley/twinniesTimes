
#' Calculates best sprint time per season and propogates it to future seasons
#' Treats initial NAs as meaning this person had not started racing yet
#' Treats Infs as person had raced in previous seasons but not this one
#' Infs are replaced with most recent time
#' NA's are replaced with Infs


carryBestForward <- function(x) {
  
  x_out <- x
  
  n_season <- length(x)
  
  ind_finite <- is.finite(x)
  
  if(any(ind_finite)) {
    
    ind_first_season <- min(which(ind_finite))
    
    if(ind_first_season<n_season) {
      
      for(k in (ind_first_season+1):n_season) {
        if(!ind_finite[k]) {
          x_out[k] <- x_out[k-1] # add + 180 here if allowing 3 minutes per season
        }
      }
    }
  }
  
  x_out[is.na(x)] <- Inf
  
  return(x_out)
}
