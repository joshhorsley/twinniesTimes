
init_RaceResults <- function(conn, paths) {

# if(FALSE) {
  
  
  
  # Load dependencies -------------------------------------------------------
  
  
  dt_memberChips <- dt_dbReadTable(conn, "memberChips")

  
  dt_memberChips[, date_assigned := as.Date(date_assigned)]
  
  dt_races_old <- dbGetQuery(conn, "SELECT date_ymd, season FROM races WHERE season < '2023-2024'") |> 
    as.data.table()
  
  dt_races_old[, date_ymd := as.Date(date_ymd)]
  
  
  # Identify and load available results -------------------------------------
  
  
  dt_races_old[, path_dir_base := file.path(paths$webscorer, season, date_ymd)]
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
  
  
  
  
  
  # New ---------------------------------------------------------------------
  
  
  dt_races_new <- dbGetQuery(conn, "SELECT date_ymd, season FROM races WHERE season >= '2023-2024'") |> 
    as.data.table()
  
  dt_races_new[, date_ymd := as.Date(date_ymd)]
  
  
  # Identify and load available results
  dt_races_new[season=="2023-2024", path_dir_base := file.path(paths$webscorer, season , "races",date_ymd, "3_INPUT_race_results")]
  dt_races_new[season!="2023-2024", path_dir_base := file.path(paths$webscorer, season, date_ymd, "3_INPUT_race_results")]
  dt_races_new[, path_results := list.files(path_dir_base, pattern = "xls$", full.names = TRUE), by = .(path_dir_base)]
  
  # dt_races_new[!is.na(path_results), dt_results := .(.(as.data.table(read_excel(path_results)))), by = path_results]
  dt_races_new[!is.na(path_results), c("dt_results", "race_format") := import_results_combined2(path_results), by = path_results]
  setattr(dt_races_new$dt_results, 'names', dt_races_new$path_results)
  
  dt_results_new <- rbindlist(dt_races_new$dt_results, fill = TRUE, idcol = "path_results")
  # [!(Adjusted.time %in% c("DNS","DNF") | Time %in% c("DNS","DNF"))]
  
  
  dt_results_new[dt_races_new, on = .(path_results),
                 `:=`(date_ymd = date_ymd,
                      race_format = i.race_format)]
  dt_results_new[, c("Place","path_results") := NULL]
  
  setnames(dt_results_new,
           c("First name","Last name","Adjusted time","Lap 1","Lap 2","Lap 3"),
           c("FirstName","LastName","AdjustedTime","Lap1","Lap2","Lap3"))
  
  
  # Join --------------------------------------------------------------------
  
  
  dt_results_all <- rbindlist(
    list(
      dt_results_old,
      dt_results_new
    ),
    use.names = TRUE,fill = TRUE)
  dt_results_all[, Bib := as.integer(Bib)]
  
  
  
  setcolorder(dt_results_all, c("date_ymd", "Bib","Name","Distance"))
  setorder(dt_results_all, Bib, date_ymd, Name)
  
  
  # Join memberChip ---------------------------------------------------------
  
  
  dates_max <- as.Date(max(dt_memberChips$date_assigned, dt_results_all$date_ymd))
  
  dt_memberChipsExpanded <- dt_memberChips[, .(date_min = min(as.Date(date_assigned))), by = chip]
  
  dt_memberChipsExpanded2 <- dt_memberChipsExpanded[, .(date_ymd = seq(from = date_min, to = dates_max, by = 7)), by = chip]
  dt_memberChipsExpanded2[dt_memberChips, on = .(chip, date_ymd == date_assigned), id_member := i.id_member]
  dt_memberChipsExpanded2[, id_member := zoo::na.locf(id_member)]
  
  dt_results_all[dt_memberChipsExpanded2, on = .(date_ymd, Bib==chip), id_member := i.id_member]
  
  setcolorder(dt_results_all, c("id_member"))
  
  setorder(dt_results_all, id_member, date_ymd)
  
  
  # Join manual participation -----------------------------------------------
  
  
  dt_manual <- read_excel(paths$manual, sheet = "resultsManualParticipation") |> 
    as.data.table()
  
  dt_manual[, date_ymd := as.Date(date_ymd)]
  dt_manual[, race_format := "manual"]
  
  dt_results_all <- rbindlist(
    list(
      dt_results_all,
      dt_manual[!is.na(date_ymd)]
    ),
    use.names = TRUE,fill = TRUE)
  
  setorder(dt_results_all, id_member, date_ymd)
  
  
  # Join teams --------------------------------------------------------------
  
  
  dt_teams_load <- read_excel(paths$manual, sheet = "teams") |> 
    as.data.table()
  
  dt_teams_load[, date_ymd := as.Date(date_ymd)]
  dt_teams_load[, total := total |> as.character() |> ymd_hms() |> format("%H:%M:%S")]
  
  dt_teams_long <- melt.data.table(dt_teams_load[!is.na(date_ymd)],
                                   id.vars = c("date_ymd","team", "rank","total"),
                                   measure.vars = patterns("bib$", "id$", "name$"),
                                   variable.name = "teamPosition",
                                   value.name = c("Bib","id_member","Name"))
  
  dt_teams_long[, teamPosition := NULL]
  dt_teams_long[, Distance := "Teams"]
  dt_teams_long[, race_format := "manual"]
  setnames(dt_teams_long, c("total","rank"), c("Time","Place"))
  
  
  
  dt_results_all <- rbindlist(
    list(
      dt_results_all,
      dt_teams_long[id_member != "VACANT"]
    ),
    use.names = TRUE,fill = TRUE)
  
  setorder(dt_results_all, id_member, date_ymd)
  
  
  # Standardise distances names ---------------------------------------------
  
  
  dt_distanceNames <- read_excel(paths$manual, sheet = "distances") |> 
    as.data.table()
  
  dt_distanceNames_long <- dt_distanceNames[, .(distanceVariant = trimws(unlist(strsplit(otherNames,split = ";")))), by = .(distanceID)]
  
  dt_results_all[, Distance_lower := tolower(Distance)]
  
  dt_results_all[dt_distanceNames_long, on = .(Distance_lower = distanceVariant), distanceID := i.distanceID]
  
  
  dt_results_all[, c("Distance", "Distance_lower") := NULL]
  setcolorder(dt_results_all, c("date_ymd", "distanceID", "id_member"))
  
  
  # Join seasons ------------------------------------------------------------
  
  
  dt_races <- dt_dbReadTable(conn, "races")
  
  dt_races[, date_ymd := as.Date(date_ymd)]
  
  dt_results_all[dt_races, on = .(date_ymd), season := i.season]
  
  setorder(dt_results_all, date_ymd)
  
  
  
  # Standardise times -------------------------------------------------------
  

  # track handicap
  # dt_results_all[!is.na(Handicap), handicapPositive := grepl("^+", Handicap)]
  
  # express all times in seconds  
  time_cols <- c("Time","AdjustedTime","Lap1","Lap2","Lap3","Handicap")
  dt_results_all[, (time_cols) := lapply(.SD, function(x) ifelse(x %in% c("-",""), NA,x)), .SDcols = time_cols]
  dt_results_all[, (time_cols) := lapply(.SD, hmsOrMsToSeconds), .SDcols = time_cols]
  
  
  
  dt_results_all[is.na(race_format) & is.na(Handicap), TimeTotal := Time]
  dt_results_all[is.na(race_format) & !is.na(Handicap), `:=`(Lap1 = Lap1 + Handicap,
                                        TimeTotal = AdjustedTime)]
  
  # dt_results_all[distanceID=="doubledistance"] |> View()
  
  dt_results_all[Lap1 < 7*60]
  dt_results_all[date_ymd=="2018-09-29", .(date_ymd,Bib, distanceID, id_member, Time, AdjustedTime, Lap1,Lap2, Lap3, Handicap, TimeTotal)]
  dt_results_all[Bib==131]
  
  dt_results_all[, Split2 := Lap1 + Lap2]
  
  dt_results_all[is.na(AdjustedTime)]
  dt_results_all[!is.na(AdjustedTime)]
  
  
  # Total races -------------------------------------------------------------
  
  
  ## pre-webscorer totals by season
  dt_totals_manual_wide <- read_excel(paths$manual, sheet = "members") |>
    as.data.table()
  
  dt_totals_old <- melt.data.table(dt_totals_manual_wide, id.vars = c("id_member"),
                                   measure.vars = patterns("^[0-9]"),
                                   variable.name = "season",
                                   value.name = "races_full", na.rm = TRUE)
  
  ## webscorer totals
  dt_totals_new_wide <-  dt_results_all[, .(races = .N), by = .(id_member,distanceID, season)] |> 
    dcast.data.table(id_member + season ~ distanceID,
                     fill = 0,
                     value.var = "races")
  
  dt_totals_new_wide[, races_full := as.integer(sprint + doubledistance)]
  
  
  
  ## by season  -------------------------------------------------------------
  
  
  dt_totals_by_season <- rbindlist(
    list(
      dt_totals_old,
      dt_totals_new_wide
    ),
    use.names = TRUE,fill = TRUE)
  
  distances <- setdiff(names(dt_totals_by_season), c("id_member","season", "sprint","doubledistance"))
  
  dt_totals_by_season[, total := rowSums(.SD, na.rm = TRUE), .SDcols = distances]
  
  setorder(dt_totals_by_season, id_member, season)
  
  distances2 <- setdiff(names(dt_totals_by_season), c("id_member","season"))
  
  # add to sqlite
  for( i_dist in distances2) {
    dbExecute(conn, glue::glue("ALTER TABLE totalRacesSeason ADD {i_dist} INT;"))
  }
  
  dbAppendTable(conn, "totalRacesSeason", dt_totals_by_season)
  
  
  ## overall  -------------------------------------------------------------
  
  
  dt_totals_all <- dt_totals_by_season[, lapply(.SD, sum, na.rm = TRUE), .SDcols = distances2, by = id_member ]
  
  # add to sqlite
  for( i_dist in distances2) {
    dbExecute(conn, glue::glue("ALTER TABLE totalRacesOverall ADD {i_dist} INT;"))
  }
  
  dbAppendTable(conn, "totalRacesOverall", dt_totals_all)
  
  
  
  
  }
  
  
  # Tests -------------------------------------------------------------------
  
  
  
  if(FALSE) {
    # check id_member
    
    # check for any missing member id
    dt_results_all[is.na(id_member)]
    
    # check by chip
    # start_from <- 120
    
    options(max.print=999999)
    
    start_from <- 1
    bibs <- unique(dt_results_all$Bib)
    bibs <- bibs[bibs>=start_from]
    
    chipcheck <- bibs[1]
    i <- 1
    
    while(chipcheck != tail(bibs)[1]) {
      chipcheck <- bibs[i];
      cat("\f")
      print(chipcheck)
      print(dt_results_all[Bib==chipcheck])
      print(dt_memberChips[chip==chipcheck])
      move <- askYesNo("Next (blank/yes), back (no)")
      if(move) {
        i <- i+1
      } else {
        i <- i-1
        
      }
    }
    
  }
  
  


# Compare totals -----------------------------------------------------------


if(FALSE) {
  
  
  dt_results_all[, .(N = .N, distanceID = list(distanceID), race_format = list(race_format)),
                 by = .(season, date_ymd, id_member)][N>1][ order(date_ymd, id_member)]
  
  
  
  
  dt_totals_overlap <- melt.data.table(dt_totals_manual_wide, id.vars = c("id_member"),
                                       measure.vars = patterns("^old"),
                                       variable.name = "season",
                                       value.name = "races_full")
  
  dt_totals_overlap <- dt_totals_overlap[races_full!=0]
  
  dt_totals_overlap[, season := gsub("^old_","", season)]
  dt_totals_overlap[, season := as.character(season)]
  
  
  # check
  dt_totals_by_season_check <- copy(dt_totals_by_season)
  
  dt_totals_by_season_check[, season := as.character(season)]
  # dt_totals_by_season_check
  
  
  dt_totals_by_season_check[dt_totals_overlap, on = .(id_member, season), races_full_dave := i.races_full ]
  
  dt_totals_by_season_check[season < "2018-2019", races_full_dave := races_full]
  
  dt_totals_by_season_check[is.na(races_full_dave), races_full_dave := 0]
  
  setcolorder(dt_totals_by_season_check, c("id_member","season","races_full_dave","races_full"))
  
  # dt_totals_by_season_check[races_full!=races_full_dave]
  # dt_totals_by_season_check[season %in% dt_totals_by_season_check$season & races_full!=races_full_dave]
  # dt_totals_by_season_check[season %in% dt_totals_by_season_check$season & races_full < races_full_dave]
  
  
  dt_totals_by_season_check[as.character(season) >= "2018-2019"][(races_full_dave > races_full)]
  dt_totals_by_season_check[as.character(season) < "2023-2024"][(races_full_dave != races_full)]
  # dt_totals_by_season_check[as.character(season) >= "2018-2019"][(races_full_dave > races_full)][season=="2019-2020"]
  # dt_totals_by_season_check[as.character(season) >= "2018-2019" & season < "2023-2024"][(races_full_dave != races_full)][id_member=="vankampen_marcel"]
  
  # dt_results_all[id_member=="torrance_alex" & season=="2018-2019"]
  dt_results_all[id_member=="vankampen_marcel" & season=="2018-2019"]
  
  
  dt_total_check <- dt_totals_by_season_check[season < "2023-2024",  lapply(.SD, sum),
                                              .SDcols = c("races_full_dave", "races_full"),
                                              by = .(id_member)]
  
  dt_total_check[races_full_dave > races_full][order(-races_full_dave)]
  dt_total_check[races_full_dave != races_full][order(-races_full_dave)]
  }
  
  