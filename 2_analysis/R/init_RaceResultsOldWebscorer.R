# webscorer results up to 2022-2023

init_RaceResultsOldWebscorer <- function(conn, path_webscorer) {
  
  
  # Load dependencies -------------------------------------------------------
  
  
  dt_memberChips <- dt_dbReadTable(conn, "memberChips")
  
  
  dt_memberChips[, date_assigned := as.Date(date_assigned)]
  
  dt_races_old <- dbGetQuery(conn, "SELECT date_ymd, season FROM races WHERE season < '2023-2024'") |> 
    as.data.table()
  
  dt_races_old[, date_ymd := as.Date(date_ymd)]
  
  # Identify and load available results -------------------------------------
  
  
  dt_races_old[, path_dir_base := file.path(path_webscorer, season, date_ymd)]
  dt_races_old[, path_dir_full := .(.(dir(path_dir_base, full.names = TRUE, no.. = TRUE))), by = date_ymd]
  
  dt_races_old_long <- dt_races_old[, .(path_dir_full = unlist(path_dir_full)), by = .(season, date_ymd)]
  dt_races_old_long[, event_name := basename(path_dir_full)]
  dt_races_old_long[, path_results := list.files(path_dir_full, pattern = "txt$", full.names = TRUE), by = .(path_dir_full)]
  
  # load results
  dt_races_old_long[!is.na(path_results), dt_results := .(.(as.data.table(read.delim(path_results)))), by = path_results]
  setattr(dt_races_old_long$dt_results, 'names', dt_races_old_long$path_results)
  
  dt_results_old <- rbindlist(dt_races_old_long$dt_results, fill = TRUE, idcol = "path_results")[
    !(Adjusted.time %in% c("DNS","DNF","DSQ") | Time %in% c("DNS","DNF","DSQ"))]
  
  
  # prep-process old webscorer results --------------------------------------
  
  
  # drop unused columns
  dt_results_old[, c("Place","Difference","X..Back","X..Winning","X..Average","X..Median","Chip.id","Start",
                     "Lap.4", "Lap.5","Lap.6",
                     "Split.1","Split.2","Split.3") := NULL]
  
  # fix misisng distances
  dt_results_old[dt_races_old_long, on = .(path_results),
                 `:=`(event_name_file = i.event_name,
                      date_ymd = i.date_ymd)]
  dt_results_old[is.na(Distance), Distance := event_name_file]
  dt_results_old[, c("event_name_file", "path_results") := NULL]
  
  # standardize distance/category
  dt_results_old[Distance %in% c("Club Champs", "Champs"), `:=`(Distance = "Sprint", Category = "Club Champs")]
  dt_results_old[tolower(Distance) %in% c("full"), `:=`(Distance = "Sprint", Category = "Non-Championship")]
  dt_results_old[tolower(Distance) %in% c("double"), `:=`(Distance = "Double Distance", Category = "Non-Championship")]
  dt_results_old[tolower(Distance) %in% c("intermediate"), `:=`(Distance = "Tempta", Category = "Non-Championship")]
  
  dt_results_old[is.na(First.name) & !is.na(First), First.name := First]
  dt_results_old[is.na(Last.name) & !is.na(Last), Last.name := Last]
  dt_results_old[, c("First","Last") := NULL]
  
  dt_results_old[is.na(Adjusted.time) & !is.na(Adjusted), Adjusted.time := Adjusted]
  dt_results_old[, Adjusted := NULL]
  
  
  dt_results_old[, Bib := as.integer(Bib)]
  
  # table(dt_results_old$Bib)
  
  # dt_results_old[, unique(tolower(Name)), by = Bib][order(Bib)] |> View()
  
  setnames(dt_results_old,
           c("First.name","Last.name","Adjusted.time","Lap.1","Lap.2","Lap.3"),
           c("FirstName","LastName","AdjustedTime","Lap1","Lap2","Lap3"))
  
  
  
  setcolorder(dt_results_old, c("date_ymd", "Bib","Name","Distance"))
  setorder(dt_results_old, Bib, date_ymd, Name)
  
  # Join memberChip ---------------------------------------------------------
  
  
  dates_max <- as.Date(max(dt_memberChips$date_assigned, dt_results_old$date_ymd))
  
  dt_memberChipsExpanded <- dt_memberChips[, .(date_min = min(as.Date(date_assigned))), by = chip]
  
  dt_memberChipsExpanded2 <- dt_memberChipsExpanded[, .(date_ymd = seq(from = date_min, to = dates_max, by = 7)), by = chip]
  dt_memberChipsExpanded2[dt_memberChips, on = .(chip, date_ymd == date_assigned), id_member := i.id_member]
  dt_memberChipsExpanded2[, id_member := zoo::na.locf(id_member)]
  
  dt_results_old[dt_memberChipsExpanded2, on = .(date_ymd, Bib==chip), id_member := i.id_member]
  
  setcolorder(dt_results_old, c("id_member"))
  setorder(dt_results_old, id_member, date_ymd)
  
  
  # Standardise distances names ---------------------------------------------
  
  
  dt_distanceNames <- dt_dbReadTable(conn, "distances")
  
  dt_distanceNames_long <- dt_distanceNames[, .(distanceVariant = trimws(unlist(strsplit(otherNames,split = ";")))), by = .(distanceID)]
  
  
  dt_results_old[, Distance_lower := tolower(Distance)]
  dt_results_old[dt_distanceNames_long, on = .(Distance_lower = distanceVariant), distanceID := i.distanceID]
  
  
  dt_results_old[, c("Distance", "Distance_lower") := NULL]
  setcolorder(dt_results_old, c("date_ymd", "distanceID", "id_member"))
  
  
  # Join seasons ------------------------------------------------------------
  
  
  
  dt_results_old[dt_races_old, on = .(date_ymd), season := i.season]
  
  setorder(dt_results_old, date_ymd)
  
  
  # Standardise times -------------------------------------------------------
  
  
  # express all times in seconds  
  time_cols <- c("Time","AdjustedTime","Lap1","Lap2","Lap3","Handicap")
  dt_results_old[, (time_cols) := lapply(.SD, function(x) ifelse(x %in% c("-",""), NA,x)), .SDcols = time_cols]
  dt_results_old[, (time_cols) := lapply(.SD, hmsOrMsToSeconds), .SDcols = time_cols]
  
  
  dt_results_old[is.na(Handicap), TimeTotal := Time]
  dt_results_old[!is.na(Handicap), `:=`(Lap1 = Lap1 + Handicap,
                                        TimeTotal = AdjustedTime)]
  
  

# Save --------------------------------------------------------------------


  dt_out <- dt_results_old[, .(date_ymd = format(date_ymd, "%Y-%m-%d"),
                               season,
                     id_member,
                     distanceID,
                     Category,
                     TimeTotal,
                     Lap1,
                     Lap2,
                     Lap3,
                     chip = Bib,
                     NameProvided = Name,
                     source = "webscorerOld")]
  
  dbAppendTable(conn, "raceResults", dt_out)
  
}