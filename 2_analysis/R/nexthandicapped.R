#' for each sprint event (raceSprint) returns the index of the next
#' handicapped event

nexthandicapped <- function(racedSprint, isHandicapped, cancelled_reason, haveResults, special_event) {
  # browser()
  if(!any(racedSprint)) return(NA)
  
  n <- length(racedSprint)
  ind_next <- rep(NA, n)
  
  for(i in seq(n)) {
    
    ind_next[i] <- if(!racedSprint[i]) {
      NA
    } else {
      which.max(((isHandicapped | special_event=="Club Champs") & !(haveResults & !racedSprint) & is.na(cancelled_reason))[(i+1):n]) + i
    }
  }
  
  return(ind_next)
}