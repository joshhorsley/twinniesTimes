
import_resultsForEdit <- function(path_xls) {
  as.data.table(read_excel(path_xls))[Time %notin% c("DNF","DNS")]
}



init_raceResultsWebscorerNew <- function(conn, path_webscorer) {
  
  dt_memberChips <- dt_dbReadTable(conn, "memberChips")
  
  dt_memberChips[, date_assigned := as.Date(date_assigned)]
  
  dt_races_new <- dbGetQuery(conn, "SELECT date_ymd, season FROM races WHERE season > '2023-2024'") |> 
    as.data.table()
  
  dt_races_new[, date_ymd := as.Date(date_ymd)]
  

# Identify and load available results -------------------------------------

  
  dt_races_new[, path_dir_base := file.path(path_webscorer, season, date_ymd, "3_INPUT_race_results")]
  dt_races_new[, path_results := list.files(path_dir_base, pattern = "^[A-Za-b0-9].*[xls|xlsx]$", full.names = TRUE), by = .(path_dir_base)]
  
  dt_races_new[!is.na(path_results), dt_results := list(list(import_resultsForEdit(path_results))), by = path_results]
  setattr(dt_races_new$dt_results, 'names', dt_races_new$path_results)
  
  dt_results_new <- rbindlist(dt_races_new$dt_results, fill = TRUE, idcol = "path_results")
  
  dt_results_new[dt_races_new, on = .(path_results),
                 `:=`(date_ymd = date_ymd)]
  dt_results_new[, c("path_results") := NULL]
  
  dt_results_new[, Bib := as.integer(Bib)]
  
  setnames(dt_results_new,
           names(dt_results_new),
           gsub(" ", "", names(dt_results_new))
  )
  
  setnames(dt_results_new, "Bib","chip")
  
  
  # Join memberChip ---------------------------------------------------------
  
  
  dates_max <- as.Date(max(dt_memberChips$date_assigned, dt_results_new$date_ymd))
  
  dt_memberChipsExpanded <- dt_memberChips[, .(date_min = min(as.Date(date_assigned))), by = chip]
  
  dt_memberChipsExpanded2 <- dt_memberChipsExpanded[, .(date_ymd = seq(from = date_min, to = dates_max, by = 7)), by = chip]
  dt_memberChipsExpanded2[dt_memberChips, on = .(chip, date_ymd == date_assigned), id_member := i.id_member]
  dt_memberChipsExpanded2[, id_member := zoo::na.locf(id_member)]
  
  dt_results_new[dt_memberChipsExpanded2, on = .(date_ymd, chip), id_member := i.id_member]
  
  setcolorder(dt_results_new, c("id_member"))
  
  setorder(dt_results_new, id_member, date_ymd)

    
  # Standardise distances names ---------------------------------------------
  
  
  dt_distanceNames <- dt_dbReadTable(conn, "distances")

  dt_distanceNames_long <- dt_distanceNames[, .(distanceVariant = trimws(unlist(strsplit(otherNames,split = ";")))), by = .(distanceID)]
  
  dt_results_new[, Distance_lower := tolower(Distance)]
  
  dt_results_new[dt_distanceNames_long, on = .(Distance_lower = distanceVariant), distanceID := i.distanceID]
  
  
  dt_results_new[, c("Distance", "Distance_lower") := NULL]
  setcolorder(dt_results_new, c("date_ymd", "distanceID", "id_member"))
  

  # Standardise times -------------------------------------------------------

  
  # express all times in seconds  
  time_cols <- c("Time","Lap1","Lap2","Lap3","Lap4","Lap5","Start","Split1","Split2","Split3","Split4","Split5")
  dt_results_new[, (time_cols) := lapply(.SD, function(x) ifelse(x %in% c("-",""), NA,x)), .SDcols = time_cols]
  dt_results_new[, (time_cols) := lapply(.SD, hmsOrMsToSeconds), .SDcols = time_cols]
  
  
  # Join seasons ------------------------------------------------------------
  
  
  dt_results_new[dt_races_new, on = .(date_ymd), season := i.season]
  setorder(dt_results_new, date_ymd)
  
  
  # Save --------------------------------------------------------------------
  
  
  dt_out <- dt_results_new[, .(date_ymd = format(date_ymd, "%Y-%m-%d"),
                               season,
                               id_member,
                               distanceID,
                               Category,
                               TimeTotal = Time,
                               Lap1,
                               Lap2,
                               Lap3,
                               Lap4,
                               Lap5,
                               Start,
                               Split1,
                               Split2,
                               Split3,
                               Split4,
                               Split5,
                               chip,
                               NameProvided = Name,
                               source = "webscorerNew")]
  
  
  
  tryCatch(
    {dbAppendTable(conn, "raceResults", dt_out)},
    error = function(e) {
      message("Failed to join race results, could this person not have an id and/or chip assigned?")
      print(dt_out[is.na(id_member)])
    }
  )
  
  
  
}