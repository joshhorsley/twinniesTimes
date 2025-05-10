init_raceResultsParticipationManual <- function(conn, path_manual) {
  
  # load results
  dt_manual <- read_excel(path_manual, sheet = "resultsManualParticipation") |> 
    as.data.table()
  
  dt_manual[, date_ymd := as.Date(date_ymd)]
  
  
  # Standardise distances names ---------------------------------------------
  
  
  dt_distanceNames <- dt_dbReadTable(conn, "distances")
  dt_distanceNames_long <- dt_distanceNames[, .(distanceVariant = trimws(unlist(strsplit(otherNames,split = ";")))), by = .(distanceID)]
  
  
  dt_manual[, Distance_lower := tolower(Distance)]
  dt_manual[dt_distanceNames_long, on = .(Distance_lower = distanceVariant), distanceID := i.distanceID]
  
  
  dt_manual[, c("Distance", "Distance_lower") := NULL]
  setcolorder(dt_manual, c("date_ymd", "distanceID", "id_member"))
  
  
  # Join seasons ------------------------------------------------------------
  
  
  dt_reaces <- dt_dbReadTable(conn, "races")
  dt_reaces[, date_ymd := as.Date(date_ymd)]
  
  dt_manual[dt_reaces, on = .(date_ymd), season := i.season]
  
  

  # Save --------------------------------------------------------------------
  
  
  dt_out <- dt_manual[!is.na(date_ymd), .(date_ymd = format(date_ymd, "%Y-%m-%d"),
                                          season,
                                          id_member,
                                          distanceID,
                                          Category,
                                          NameProvided = Name,
                                          source = "manualParticipation")]
  
  
  dbAppendTable(conn, "raceResults", dt_out)
  
}

if(FALSE) {
  path_manual <- paths$manual
  
}