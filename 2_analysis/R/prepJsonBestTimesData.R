prepJsonBestTimesData <- function(conn,
                                  path_source,
                                  path_bestTimeData) {
  
  
  # Load --------------------------------------------------------------------
  
  
  dt_raceResults <- dt_dbReadTable(conn, "raceResults")[season>="2024-2025" & distanceID != "teams"]
  dt_members <- dt_dbReadTable(conn, "members")
  dt_distances <- dt_dbReadTable(conn, "distances")
  
  
  # Get Best times ----------------------------------------------------------
  
  
  cols <- c("TimeTotal","Lap1","Lap2","Lap3","Lap4","Lap5")
  
  dt_bestBySeason <- dt_raceResults[!is.na(TimeTotal), lapply(.SD, min), .SDcols = cols, by = .(id_member, distanceID,season)  ]
  dt_bestOverall <- dt_raceResults[!is.na(TimeTotal), lapply(.SD, min), .SDcols = cols, by = .(id_member, distanceID)  ]
  
  
  dt_bestBySeason[, (cols) := lapply(.SD, seconds_to_hms_simple), .SDcols = cols]
  dt_bestOverall[, (cols) := lapply(.SD, seconds_to_hms_simple), .SDcols = cols]
  
  
  date_update_display <- dt_raceResults$date_ymd |> max() |> toNiceDate()
  
  
  # Season list  ------------------------------------------------------------
  
  
  dt_seasonList_all <- data.table(season = "all", season_display = "2024/25 Onwards")
  
  dt_seasonList_seasons <- dt_bestBySeason[, .(season_display = as.character(seasonNice(season))), by = season]
  setorder(dt_seasonList_seasons, -season)
  
  dt_seasonList <- rbindlist(
    list(
      dt_seasonList_all,
      dt_seasonList_seasons
    )
  )
  
  # race list flat
  dt_seasonList |> 
    toJSON() |> 
    write(file.path(path_source, "bestTimesSeasonList.json"))
  
  
  # Overall -----------------------------------------------------------------
  
  
  # format
  dt_bestOverall[dt_members, on = .(id_member), name_display := i.name_display]  
  
  dt_tablePrepOverall <- dt_bestOverall[, .(raceData = list(list(data.table(
    id_member = id_member,
    name_display = name_display,
    TimeTotal = TimeTotal,
    Lap1 = Lap1,
    Lap2 = {if(!all(is.na(Lap2)))  Lap2},
    Lap3 = {if(!all(is.na(Lap3)))  Lap3},
    Lap4 = {if(!all(is.na(Lap4)))  Lap4},
    Lap5 = {if(!all(is.na(Lap5)))  Lap5}
  )) |> setNames(distanceID))), by = .(distanceID)]  
  
  dt_distances_overall <- dt_distances[distanceID %in% dt_tablePrepOverall$distanceID, .(distanceID, distanceDisplay)]
  
  # export
  list_export <- (list(
    season = dt_seasonList_all$season,
    season_display = dt_seasonList_all$season_display,
    dateUpdated = date_update_display,
    tabData = list(data = dt_tablePrepOverall$raceData |> unlist(recursive = FALSE),
                   distances = dt_distances_overall)
  ))
  
  list_export |> 
    toJSON(pretty = TRUE) |> 
    write(file.path(path_bestTimeData, "all.json"))
  
  
  
  # By Season ---------------------------------------------------------------
  
  
  # format
  dt_bestBySeason[dt_members, on = .(id_member), name_display := i.name_display]  
  
  dt_tablePrepSeason1 <- dt_bestBySeason[, .(raceData = list(list(data.table(
    id_member = id_member,
    name_display = name_display,
    TimeTotal = TimeTotal,
    Lap1 = Lap1,
    Lap2 = {if(!all(is.na(Lap2)))  Lap2},
    Lap3 = {if(!all(is.na(Lap3)))  Lap3},
    Lap4 = {if(!all(is.na(Lap4)))  Lap4},
    Lap5 = {if(!all(is.na(Lap5)))  Lap5}
  )) |> setNames(distanceID))), by = .(distanceID, season)]  
  
  
  
  dt_tablePrepSeason2 <- dt_tablePrepSeason1[, .(seasonData = list(list((unlist(raceData,recursive = FALSE))) )), by = .(season)]
  
  
  # export
  for(i in seq(nrow(dt_seasonList_seasons))) {
    
    season_i <- dt_seasonList_seasons[i]$season
    
    list_export <- (list(
      season = dt_seasonList_seasons[i]$season,
      season_display = dt_seasonList_seasons[i]$season_display,
      dateUpdated = date_update_display,
      tabData = list(data = dt_tablePrepSeason2[season==season_i]$seasonData |> unlist(recursive = FALSE) |> unlist(recursive = FALSE),
                     distances =  dt_distances[distanceID %in% dt_bestBySeason[season==season_i]$distanceID, .(distanceID, distanceDisplay)])
    ))
    
    list_export |> 
      toJSON(pretty = TRUE) |> 
      write(file.path(path_bestTimeData, glue("{season}.json", season = season_i)))
    
  }
}