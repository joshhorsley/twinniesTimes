prepJsonTotalRaces <- function(conn, path_source, path_totalRacesData) {
  
  
  # Load --------------------------------------------------------------------
  
  
  dt_totalRacesOverall <-  dt_dbReadTable(conn, "totalRacesOverall")
  dt_members <-  dt_dbReadTable(conn, "members")
  dt_distances <- dt_dbReadTable(conn, "distances")
  
  dt_totalRacesSeason <- dt_dbReadTable(conn, "totalRacesSeason")
  
  dateUpdated <- dbGetQuery(conn, "SELECT MAX(date_ymd) AS dateMax FROM raceResults")$dateMax |> 
    toNiceDate()
  
  season_first_multi_distance <- "2018-2019"
  
  
  # Point Seasons list ------------------------------------------------------
  
  
  dt_seasonList_byDistance <- data.table(season = "byDistance", season_display = "By Distance")
  dt_seasonList_bySeason <- data.table(season = "bySeason", season_display = "By Season")
  
  dt_seasonList_seasons <- dt_totalRacesSeason[season >= season_first_multi_distance, .(season_display = as.character(seasonNice(season))),by = .(season)]
  setorder(dt_seasonList_seasons, -season)
  
  
  dt_seasonList <- rbindlist(
    list(
      dt_seasonList_byDistance,
      dt_seasonList_bySeason,
      dt_seasonList_seasons
    )
  )
  
  # race list flat
  path_totalRacesSeasonList <- file.path(path_source, "totalRacesSeasonList.json")
  
  dt_seasonList |> 
    toJSON() |> 
    write(path_totalRacesSeasonList)
  
  
  # Notes -------------------------------------------------------------------
  
  
  dt_totalDistanceNotes <- list(races_full =  "Includes Sprint (previously Full) and Double Distance events.",
                                races_all = "In addition to Sprint+, this includes Tempta (previously Intermediate), Aquabike, Swimrun, and Teams but records for these are not comprehensive.",
                                sprint = "Since 2018/19 seson",
                                tempta = "Since 2018/19 seson",
                                doubledistance = "Since 2018/19 seson",
                                teams = "Since 2018/19 season, not comprehensive"
                                
  ) |> 
    list_to_dt()
  
  
  
  # By Distance -------------------------------------------------------------
  
  
  dt_totalRacesOverall[dt_members, on = .(id_member), `:=`(name_display = i.name_display)]
  
  
  dt_cols_all <- data.table(columnID = c("name_display", "races_full","races_all", dt_distances[distanceID %in% names(dt_totalRacesOverall)]$distanceID),
                            title = c("Name", "Sprint+","All*", dt_distances[distanceID %in% names(dt_totalRacesOverall)]$distanceDisplay))
  
  
  dt_cols_all[dt_totalDistanceNotes, on = .(columnID = name), note := i.value]
  
  cols_use <- c("id_member",dt_cols_all$columnID)
  
  
  ## Save
  list_export <- list(
    dateUpdated = dateUpdated,
    totalData = dt_totalRacesOverall[order(-races_full), ..cols_use],
    colsUse = dt_cols_all[columnID != "name_display"],
    season = dt_seasonList_byDistance$season,
    season_display = dt_seasonList_byDistance$season_display
  )
  
  list_export |> 
    jsonlite::toJSON() |>
    write(file.path(path_totalRacesData, glue("{season}.json", season=dt_seasonList_byDistance$season)))
  
  
  # Per season --------------------------------------------------------------
  
  
  dt_totalRacesSeason[dt_members, on = .(id_member), `:=`(name_display = i.name_display)]
  
  
  for(i_season in unique(dt_totalRacesSeason$season)) {
    
    # drop columns without any results for season
    dt_total_current <- dt_totalRacesSeason[season==i_season]
    
    dt_total_current_long <- dt_total_current |> 
      melt.data.table(id.vars = c("id_member","season", "name_display"),
                      variable.name = "distanceID",
                      value.name = "count")
    
    dt_total_current_use <- dt_total_current_long[!is.na(count)][count!=0] |> 
      dcast.data.table(id_member + name_display ~ distanceID,value.var = "count")
    
    dt_cols_current <- dt_cols_all[columnID %in% names(dt_total_current_use)]
    
    cols_use_current <- c("id_member",dt_cols_current$columnID)
    
    
    ## Save
    list_export <- list(
      dateUpdated = dateUpdated,
      totalData = dt_total_current_use[order(-races_full), ..cols_use_current],
      colsUse = dt_cols_current[columnID != "name_display"],
      season = i_season,
      season_display = seasonNice(i_season)
    )
    
    list_export |> 
      jsonlite::toJSON() |>
      write(file.path(path_totalRacesData, glue("{season}.json", season=i_season)))
    
  }
  
  
  # By Season ---------------------------------------------------------------
  
  
  dt_totalBySeason <- dt_totalRacesSeason[
    , 
    .(id_member, season, races_all,name_display)] |> 
    dcast.data.table(id_member + name_display ~ season, value.var="races_all")
  
  dt_cols_bySeason <- dt_totalRacesSeason[, .(columnID = sort(unique(season)))]
  dt_cols_bySeason[, title := as.character(seasonNice(columnID))]
  dt_cols_bySeason[, note := NA]
  
  ## Save
  list_export <- list(
    dateUpdated = dateUpdated,
    totalData = dt_totalBySeason,
    colsUse = dt_cols_bySeason,
    season = dt_seasonList_bySeason$season,
    season_display = dt_seasonList_bySeason$season_display
  )
  
  list_export |> 
    jsonlite::toJSON() |>
    write(file.path(path_totalRacesData, glue("{season}.json", season=dt_seasonList_bySeason$season)))
  
}