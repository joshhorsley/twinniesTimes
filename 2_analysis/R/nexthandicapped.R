#' for each sprint event (raceSprint) returns the index of the next
#' handicapped event

nexthandicapped <- function(racedSprint, isHandicapped) {
  
  if(!any(racedSprint)) return(NA)
  
  n <- length(racedSprint)
  ind_next <- rep(NA, n)
  
  for(i in seq(n)) {
    
    ind_next[i] <- if(!racedSprint[i]) {
      NA
    } else {
      which.max(isHandicapped[(i+1):n]) + i
    }
  }
  
  return(ind_next)
}