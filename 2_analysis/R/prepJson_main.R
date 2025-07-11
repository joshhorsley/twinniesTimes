prepJson_main <- function(conn, path_source) {
  
  dt_raceResults <- dt_dbReadTable(conn, "raceResults")
  dt_timesBestPoints <- dt_dbReadTable(conn, "timesBestPoints")
  
  date_latest <- max(dt_raceResults$date_ymd)
  points_season_max <- dt_timesBestPoints[points_all_awarded>0, max(season)]
  
  dateMain <- list(latestRace = list(date_ymd = date_latest),
                   latestPoints = list(season = points_season_max))
  
  dateMain |> 
    toJSON() |> 
    write(file.path(path_source, "main.json"))
  
}
