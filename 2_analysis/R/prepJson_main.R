prepJson_main <- function(conn, path_source) {
  
  
  date_latest <- dt_raceResults_check <- dt_dbReadTable(conn, "raceResults")$date_ymd |> max()

  
  dateMain <- list(latestRace = list(date_ymd = date_latest))
  
  dateMain |> 
    toJSON() |> 
    write(file.path(path_source, "main.json"))
  
}
