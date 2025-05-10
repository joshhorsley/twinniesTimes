
init_seasons <- function(conn, path_manual) {
  
  dt_in <- read_excel(path_manual,sheet = "seasons") |> 
    as.data.table()
  
  dbAppendTable(conn, "seasons", dt_in[, .(season)])
}

init_races <- function(conn, path_manual, start_default  =  "06:00" ) {
  
  dt_races <- read_excel(path_manual,sheet = "races") |> 
    as.data.table()
  
  # set default start at 6
  dt_races[, start_time_change := format(start_time_change, "%H:%M")]
  dt_races[is.na(start_time_change), start_time_change := start_default]
  
  dbAppendTable(conn, "races", dt_races[, .(date_ymd = format(date_ymd, "%Y-%m-%d"),
                                            season,
                                            special_event,
                                            external,
                                            start_time_change,
                                            delay_points,
                                            cancelled_reason)])
}


init_distances <- function(conn, path_manual) {
  
  dt_in <- read_excel(path_manual,sheet = "distances") |> 
    as.data.table()
  
  dbAppendTable(conn, "distances", dt_in[, .(distanceID, distanceDisplay, otherNames, parts)])
}
