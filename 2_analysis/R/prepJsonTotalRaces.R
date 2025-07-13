prepJsonTotalRaces <- function(conn, path_source) {
  
  
  
  # Load --------------------------------------------------------------------
  
  
  dt_totalRacesOverall <-  dt_dbReadTable(conn, "totalRacesOverall")
  dt_members <-  dt_dbReadTable(conn, "members")
  dt_distances <- dt_dbReadTable(conn, "distances")
  
  dateUpdated <- dbGetQuery(conn, "SELECT MAX(date_ymd) AS dateMax FROM raceResults")$dateMax |> 
    toNiceDate()
  
  
  
  
  # Prep --------------------------------------------------------------------
  
  
  dt_totalRacesOverall[dt_members, on = .(id_member), `:=`(name_display = i.name_display)]
  
  
  dt_cols <- data.table(columnID = c("name_display", "races_full","races_all", dt_distances[distanceID %in% names(dt_totalRacesOverall)]$distanceID),
                        title = c("Name", "Sprint+","All*", dt_distances[distanceID %in% names(dt_totalRacesOverall)]$distanceDisplay))
  
  
  
  dt_totalDistanceNotes <- list(races_full =  "Includes Sprint (previously Full) and Double Distance events.",
                                races_all = "In addition to Sprint+, this includes Tempta (previously Intermediate), Aquabike, Swimrun, and Teams but records for these are not comprehensive.",
                                sprint = "Since 2018/19 seson",
                                tempta = "Since 2018/19 seson",
                                doubledistance = "Since 2018/19 seson",
                                teams = "Since 2018/19 season, not comprehensive"
                                
  ) |> 
    list_to_dt()
  
  
  dt_cols[dt_totalDistanceNotes, on = .(columnID = name), note := i.value]
  
  # dt_cols[, freeze := columnID == "name_dispaly"]
  
  cols_use <- c("id_member",dt_cols$columnID)
  
  
  # Save --------------------------------------------------------------------
  
  
  list_export <- list(
    dateUpdated = dateUpdated,
    totalData = dt_totalRacesOverall[order(-races_full), ..cols_use],
    colsUse = dt_cols[columnID != "name_display"]
  )
  
  
  list_export |> 
  jsonlite::toJSON() |>
    write(file.path(path_source, "totalRaces.json"))
  
  
}