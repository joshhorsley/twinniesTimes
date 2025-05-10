
dt_dbReadTable <- function(conn, name, ...) {
  as.data.table(DBI::dbReadTable(conn, name, ...))
}


list_to_dt <- function(l) {
  data.table(name = names(l),
             value = unname(unlist(l))
  )
}


toNiceDate <- function(x) {
  trimws(format(as.Date(x), "%e %b %Y"))
}


toNiceDateShort <- function(x) {
  trimws(format(as.Date(x), "%e %b"))
}


hmToSeconds <- function(x) as.numeric(seconds(hm(x)))


hmsOrMsToSeconds <- function(x) {
  
  
  out <- numeric(length(x))
  
  ind_isNA <- is.na(x)
  
  # check for no colons
  ind_nocolons <- !grepl(":", x[!ind_isNA])
  
  if(any(ind_nocolons)) {
    print(x[!ind_isNA][ind_nocolons])
    stop("Found a non NA entry with no colons")
  }
  
  out[ind_isNA] <- NA
  
  n_colons <- gregexec(":",x[!ind_isNA]) |>
    lapply(function(x) length(x[1,])) |> 
    unlist()
  
  if(any(n_colons %in% c(0,3))) stop("Encountered a time with unexpected number of colons")
  
  out[!ind_isNA][n_colons==1] <- as.numeric(seconds(ms(x[!ind_isNA][n_colons==1])))
  out[!ind_isNA][n_colons==2] <- as.numeric(seconds(hms(x[!ind_isNA][n_colons==2])))
  
  return(out)
  
}


seconds_to_hms_simple <- function(x, drop_leading_0 = FALSE) {
  
  span <- as.double(x)
  remainder <- abs(span)
  hours_i <- remainder%/%(3600)
  remainder <- remainder%%(3600)
  minutes_i <- remainder%/%(60)
  seconds_i <- remainder%%(60)
  
  out <- ifelse(
    is.na(x),
    NA,
    sprintf("%01d:%02d:%02d", hours_i, minutes_i,seconds_i)
  )
  
  
  out
}




# Season display ----------------------------------------------------------


seasonNice <- function(season) {
  glue("{first}/{second}",
       first = substring(season, 1,4),
       second = substring(season, 8,9))
}


# Ordinal suffix ----------------------------------------------------------


ordinal_suffix_of <- function(i) {
  
  dt_ordinal <- data.table(i = i)
  dt_ordinal[,`:=`(j = i %% 10,
                   k = i %% 100)]
  
  dt_ordinal[j == 1 & k != 11, result := paste0(i,"st")]
  dt_ordinal[j == 2 & k != 12, result := paste0(i,"nd")]
  dt_ordinal[j == 3 & k != 13, result := paste0(i,"rd")]
  dt_ordinal[is.na(result), result := paste0(i, "th")]
  
  dt_ordinal$result
}


# Paste drop --------------------------------------------------------------


pasteDropNA <- function(x, collapse = "\n") {
  paste0(x[!is.na(x)], collapse = collapse)
}


pasteDropEmpty <- function(x, collapse = "\n") {
  paste0(x[x!=""], collapse = collapse)
}



# cumulative sum ignore NA ------------------------------------------------


cumsum_omitNA <- function(x) {
  
  out <- integer(length(x))
  
  ind_NA <- is.na(x)
  
  out[ind_NA] <- NA
  out[!ind_NA] <- cumsum(x[!ind_NA])
  
  return(out)
  
  
}


