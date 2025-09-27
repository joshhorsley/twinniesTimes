
if(FALSE) {
  path_source <- pathsWebsiteData$source
  path_raceData <- pathsWebsiteData$raceData
}

prepJsonRaceData <- function(conn,
                             path_source,
                             path_raceData
) {
  
  
  # Load --------------------------------------------------------------------
  
  
  dt_races <- dt_dbReadTable(conn, "races")
  dt_raceResults <- dt_dbReadTable(conn, "raceResults")
  dt_members <-  dt_dbReadTable(conn, "members")
  dt_distances <- dt_dbReadTable(conn, "distances")
  dt_bestPoints <- dt_dbReadTable(conn, "timesBestPoints")
  dt_marshalling <- dt_dbReadTable(conn, "marshalling")
  dt_totalRacesDate <- dt_dbReadTable(conn, "totalRacesDate")
  
  
  # Offset for early starts -------------------------------------------------
  
  
  dt_races[, secondsOffset := hmToSeconds(start_time_change)]
  
  
  # Race list ---------------------------------------------------------------
  
  
  dt_racesList <- dt_races[season>="2024-2025" & date_ymd %in% dt_raceResults$date_ymd]
  setorder(dt_racesList, -date_ymd)
  
  dt_racesList[, date_ymd := ymd(date_ymd)]
  dt_racesList[, date_display := date_ymd |> format("%e %b %Y") |> trimws()]
  
  # race list flat
  path_raceListFlat <- file.path(path_source, "raceListFlat.json")
  
  dt_racesList[, .(date_ymd, date_display)] |> 
    toJSON() |> 
    write(path_raceListFlat)
  
  
  # race list in seasons
  path_raceListHierarchy <- file.path(path_source, "raceListHierarchy.json")
  
  dt_racesList[, season_display := seasonNice(season)]
  dt_racesList[, extraNote := special_event]
  
  dt_racesList[, .(options = list(
    data.table(date_ymd,
               date_display,
               cancelled_reason,
               extraNote)
  )),
  by = .(season, season_display)] |> 
    
    toJSON() |>
    write(path_raceListHierarchy)
  
  
  # Result type -------------------------------------------------------------
  
  
  dt_racesList[, haveTable := extraNote == "Teams"]
  dt_racesList[is.na(haveTable),  haveTable := FALSE]
  
  
  # Points changes ----------------------------------------------------------
  
  
  dt_bestPoints[, rankIsEqual := .N>1, by = .(date_ymd, season, rank_all_total)]
  
  dt_bestPoints[, points_all_total_previous := shift(points_all_total), by = .(id_member, season)]
  dt_bestPoints[, rank_all_total_previous := shift(rank_all_total), by = .(id_member, season)]
  dt_bestPoints[, rankIsEqual_previous := shift(rankIsEqual), by = .(id_member, season)]
  
  
  
  ## 2024-2025 Regular races -------------------------------------------------
  
  
  dt_prep_2024_2025 <- dt_raceResults[season>="2024-2025"]
  
  dt_prep_2024_2025[dt_members, on = .(id_member), name_display := i.name_display]
  dt_prep_2024_2025[dt_distances, on = .(distanceID), distanceDisplay := i.distanceDisplay]
  dt_prep_2024_2025[dt_bestPoints[id_member %in% dt_prep_2024_2025[distanceID=="sprint"]$id_member],
                    on = .(id_member, date_ymd),
                    `:=`(timeBestPrevious = i.timeBestPreviousUse,
                         timeDiff = i.timeDiff,
                         points_handicap_awarded = i.points_handicap_awarded)]
  
  dt_prep_2024_2025[dt_races, on = .(date_ymd), secondsOffset := i.secondsOffset]
  
  
  ## Layout --------------------------------------------------------------------
  
  
  # include non-timed too
  dt_dist_cat_unique <- dt_prep_2024_2025[, .(racers = .N,
                                              racers_timed = sum(!is.na(TimeTotal)),
                                              secondsOffset = secondsOffset[1]
  ), by = .(date_ymd, distanceID, Category)]
  
  # adjust for earlier starts
  dt_dist_cat_unique[, tickvals_max := 6300 + (21600 - secondsOffset)]
  dt_dist_cat_unique[, ticktext := ifelse(secondsOffset==18900,
                                          list(list(c("5:15","5:30","","6:00","","6:30","","7:00","","7:30",""))),
                                          list(list(c("6:00","","6:30","","7:00","","7:30","")))),
                     by = .(Category, distanceID, date_ymd)]
  dt_dist_cat_unique[, ticktextZero := ifelse(secondsOffset==18900,
                                              list(list(c("0:00","","0:30","","1:00","","1:30","","2:00","","3:00"))),
                                              list(list(c("0:00","","0:30","","1:00","","1:30","")))),
                     by = .(Category, distanceID, date_ymd)]
  
  dt_layoutAxes <- dt_dist_cat_unique[, .(
    xaxis = list(list(
      tickvals = seq(from = 0, to = tickvals_max, by =900),
      ticktext = ticktext[[1]],
      ticktextZero = ticktextZero[[1]]
    )),
    racers = racers
  ), by = .(date_ymd, distanceID, Category)]
  
  
  # Data --------------------------------------------------------------------
  
  
  dt_distanceParts <- dt_distances[, .(
    part = trimws(unlist(strsplit(parts,split = ";")))
  ), by = .(distanceID)]
  dt_distanceParts[, lap := as.character(glue("Lap{lapNumber}", lapNumber = seq(.N))), by = distanceID]
  dt_distanceParts[, split := as.character(glue("Split{lapNumber}", lapNumber = seq(.N))), by = distanceID]
  
  dt_distanceParts[, lapInt := seq(.N), by = distanceID]
  
  dt_distancePartsSummary <- dt_distanceParts[, .(part = list(part),
                                                  lap = list(lap),
                                                  split = list(split),
                                                  nLaps = .N,
                                                  lapSplit = list(c(lap,split))), by = distanceID]
  
  varsCommon <- c("id_member","Start","part")
  
  dt_distancePartsSummary[, varsUse := lapply(lapSplit, function(x) list(c(varsCommon, x))), by = distanceID]
  
  
  
  # data prep
  dt_plotPrep_2024_25 <- dt_raceResults[season=="2024-2025"]
  dt_plotPrep_2025_26_races <- dt_raceResults[season>="2025-2026"]
  
  dt_plotPrep_2024_25[, raced := TRUE]
  dt_plotPrep_2025_26_races[, raced := TRUE]
  
  # for 2025/26 conwards also include marshalling for race points table
  dt_marshalling[dt_races, on = .(date_ymd), season := i.season]
  
  dt_plotPrep_2025_26 <- rbindlist(
    list(
      dt_plotPrep_2025_26_races,
      dt_marshalling[season>="2024-2026", .(date_ymd, id_member, raced = FALSE)]
    ),
    use.names = TRUE,
    fill = TRUE)
  
  
  dt_plotPrep <- rbindlist(
    list(
      dt_plotPrep_2024_25,
      dt_plotPrep_2025_26
    ))
  
  
  # check haven't got marshalling and timing results
  stopifnot(nrow(dt_plotPrep[, .N, by = .(id_member,date_ymd)][N>1])==0)
  
  
  dt_plotPrep[dt_members, on = .(id_member), name_display := i.name_display]
  dt_plotPrep[dt_bestPoints[id_member %in% dt_plotPrep[distanceID=="sprint"]$id_member],
              on = .(id_member, date_ymd),
              `:=`(timeBestPrevious = i.timeBestPreviousUse,
                   timeDiff = i.timeDiff,
                   points_handicap_awarded = i.points_handicap_awarded,
                   points_participation_awarded = i.points_participation_awarded,
                   points_all_awarded = i.points_all_awarded,
                   points_all_total = i.points_all_total,
                   points_all_total_previous = i.points_all_total_previous,
                   rank_all_total = i.rank_all_total,
                   rank_all_total_previous = i.rank_all_total_previous,
                   rankIsEqual = i.rankIsEqual,
                   rankIsEqual_previous = i.rankIsEqual_previous)]
  
  dt_plotPrep[dt_distancePartsSummary, on = .(distanceID), `:=`(lapSplit = i.lapSplit,
                                                                varsUse = i.varsUse,
                                                                part= i.part)]
  
  dt_plotPrep[, Split0 := Start]
  setcolorder(dt_plotPrep, "Split0") #make sure it's the first split variable
  
  # Rank total time
  dt_plotPrep[, rankTotal := frank(TimeTotal, ties.method = "first"), by = .(date_ymd, distanceID, Category)]
  dt_plotPrep[, yTotal := .N - rankTotal, by = .(date_ymd, distanceID, Category)]
  
  # Rank finish time
  dt_plotPrep[, rankFinish := frank(TimeTotal + Start, ties.method = "first"), by = .(date_ymd, distanceID, Category)]
  dt_plotPrep[, yFinish := .N - rankFinish, by = .(date_ymd, distanceID, Category)]
  
  
  dt_plotPrep_long <- melt.data.table(
    dt_plotPrep,
    id.vars = c("date_ymd","id_member","name_display","distanceID","Start","Category","TimeTotal","rankTotal", "yTotal", "yFinish"),
    measure.vars = patterns("^Split","^Lap"),
    variable.name = "lap",
    variable.factor = FALSE,
    value.name = c("x0","dx"))[order(date_ymd,distanceID,id_member,Category,lap)]
  
  dt_plotPrep_long[, x1 := shift(x0,n = -1L), by = .(date_ymd, id_member)]
  dt_plotPrep_long[, xCum := x1 - Start]
  dt_plotPrep_long[, x0Common := x0 - Start]
  dt_plotPrep_long[, Start := NULL]
  
  dt_plotPrep_long[, dx_hms := seconds_to_hms_simple(dx)]
  dt_plotPrep_long[, xCum_hms := seconds_to_hms_simple(xCum)]
  dt_plotPrep_long[, TimeTotal_hms := seconds_to_hms_simple(TimeTotal)]
  
  dt_plotPrep_long[, lap := as.integer(lap)]
  
  dt_plotPrep_long[dt_distancePartsSummary, on = .(distanceID), nLaps := i.nLaps]
  
  dt_plotPrep_long2 <- dt_plotPrep_long[lap <= nLaps]
  dt_plotPrep_long2[, nLaps := NULL]
  
  dt_plotPrep_long2[dt_distanceParts, on = .(lap = lapInt,distanceID), lapType := i.part]
  
  dt_plotPrep_long2[, lapDisplay := tools::toTitleCase(lapType)]
  
  dt_plotPrep_long3 <- dt_plotPrep_long2[, .(catData = list(list(
    id_member = id_member,
    name_display = name_display,
    x0Clock = x0,
    x0Common = x0Common,
    dx = dx,
    yTotal = yTotal,
    yFinish = yFinish,
    
    dx_hms = dx_hms,
    xCum_hms = xCum_hms,
    TimeTotal_hms = TimeTotal_hms
    
  ))
  ), by = .(date_ymd, distanceID, Category, lapType, lapDisplay, lap)]
  
  dt_plotPrepDistances <- dt_plotPrep_long3[, .(distanceID = unique(distanceID)), by = .(date_ymd)]
  dt_plotPrepDistances[dt_distances, on = .(distanceID), distanceDisplay := i.distanceDisplay]
  
  dt_plotPrepCategories <- dt_plotPrep_long3[, .(Category = unique(Category)), by = .(date_ymd, distanceID)]
  
  
  # Annotations -------------------------------------------------------------
  
  
  dt_plotPrep[, points_handicap_display := ifelse(is.na(points_handicap_awarded), 0, points_handicap_awarded)]
  
  dt_annotatopnPrep <- dt_plotPrep[, .(annotations = list(list(
    x0Clock = TimeTotal + Start,
    x0Common = TimeTotal,
    yTotal = yTotal,
    yFinish = yFinish,
    name_display = name_display,
    points_handicap_display = points_handicap_display,
    timeDiff = timeDiff
  )
  )), by = .(date_ymd, distanceID, Category)]
  
  
  # Table - non-teams -------------------------------------------------------
  
  
  dt_tablePrep <- data.table::copy(dt_plotPrep)
  
  
  dt_tablePrep2 <- dt_tablePrep[, .(catData = list(list(data.table(
    id_member = id_member,
    name_display = name_display,
    TimeTotalDisplay = seconds_to_hms_simple(TimeTotal),
    rankTotal = rankTotal,
    Lap1 = seconds_to_hms_simple(Lap1),
    Lap2 = seconds_to_hms_simple(Lap2),
    Lap3 = seconds_to_hms_simple(Lap3),
    Lap4 = seconds_to_hms_simple(Lap4),
    Lap5 = seconds_to_hms_simple(Lap5),
    timeDiff = {if(!all(is.na(timeDiff)))  timeDiff},
    timeDiffDisplay = {if(!all(is.na(timeDiff)))  glue("{plus}{timeDiff}", plus=ifelse(timeDiff>0,"+",""), timeDiff = timeDiff)},
    points_handicap_awarded = {if(!all(is.na(points_handicap_awarded)))  points_handicap_awarded}
  )) |> setNames(Category))), by = .(date_ymd, distanceID, Category)]
  
  dt_tablePrep3 <- dt_tablePrep2[, .(distData = list(list((unlist(catData,recursive = FALSE))) |> setNames(distanceID))), by = .(date_ymd,distanceID)]
  dt_tablePrep4 <- dt_tablePrep3[, .(raceData = list(list((unlist(distData,recursive = FALSE))) |> setNames(date_ymd))), by = .(date_ymd)]
  
  
  
  # Points table ------------------------------------------------------------
  
  
  dt_pointsTablePrep <- dt_plotPrep[points_all_awarded!=0, .(pointsData = (list(data.table(
    id_member = id_member,
    name_display = name_display,
    points_all_total_previous = {if(!all(is.na(points_all_total_previous))) points_all_total_previous},
    rank_all_total_previousDisplay = {if(!all(is.na(points_all_total_previous)))  ordinal_suffix_of(rank_all_total_previous)},
    points_handicap_awarded = points_handicap_awarded,
    points_participation_awarded = points_participation_awarded,
    points_all_awarded = points_all_awarded,
    points_all_total = points_all_total,
    rank_all_total= rank_all_total,
    rank_all_totalDisplay = ordinal_suffix_of(rank_all_total),
    rankIsEqual = rankIsEqual,
    rankIsEqual_previous = {if(!all(is.na(points_all_total_previous)))  rankIsEqual_previous}
  )))), by = .(date_ymd)]  
  
  
  # Table - Teams -----------------------------------------------------------
  
  
  dt_tabTeamsManualLong <- dt_prep_2024_2025[distanceID=="teams" & source == "teamsManual",
                                             .(id_member, name_display, teamID, TimeTotal),
                                             by = .(season, date_ymd)]
  
  dt_tabTeamsManualLong[, TimeTotalDisplay := seconds_to_hms_simple(TimeTotal)]
  
  dt_tabTeamsManual <- dt_tabTeamsManualLong[, .(
    list_id_member = list(id_member),
    list_name_display = list(name_display)),
    by = .(date_ymd, teamID, TimeTotal, TimeTotalDisplay)]
  
  list_teamsManual <- split(dt_tabTeamsManual, by = "date_ymd")
  
  
  # Marshalling -------------------------------------------------------------
  
  
  dt_marshalling[dt_members, on = .(id_member), name_display := i.name_display]
  
  dt_marshallingPrep <- dt_marshalling[, .(marshalling = list(list(
    id_member=id_member,
    name_display = name_display
  ))
  ), by = .(id_member, date_ymd)]
  
  dt_marshallingPrep2 <- dt_marshallingPrep[, .(marshalling = list(list(marshalling))), by = date_ymd]
  
  
  # Newcomers ---------------------------------------------------------------
  
  
  dt_totalRacesDate[dt_members, on = .(id_member), `:=`(name_display = i.name_display,
                                                        totalRacesMetric = i.totalRacesMetric)]
  
  dt_newcomersPrep <- dt_totalRacesDate[races_all==1, .(milestones = list(list(
    id_member = id_member,
    name_display = name_display
  ))), by = .(id_member, date_ymd)]
  
  dt_newcomersPre2 <- dt_newcomersPrep[, .(milestones = list(list(milestones))), by = date_ymd]
  setorder(dt_newcomersPre2, date_ymd)
  
  
  # Milestones --------------------------------------------------------------
  
  
  milestones_use <- seq(from = 50, to = 1000, by = 50)
  
  dt_totalRacesDate[, races_use := ifelse(totalRacesMetric=="full",races_full, races_all)]
  
  dt_milestonesPrep <- dt_totalRacesDate[races_use %in% milestones_use, .(milestones = list(list(
    id_member = id_member,
    name_display = name_display,
    races_use = races_use
  ))), by = .(id_member, date_ymd)]
  
  dt_milestonesPre2 <- dt_milestonesPrep[, .(milestones = list(list(milestones))), by = date_ymd]
  setorder(dt_milestonesPre2, date_ymd)
  
  
  # Race stats --------------------------------------------------------------
  
  
  dt_race_stats <- dt_prep_2024_2025[, .(n_entered = .N,
                                         n_handicapAwards = sum(points_handicap_awarded > 0, na.rm = TRUE)), by = .(date_ymd)]
  
  
  # Save --------------------------------------------------------------------
  
  
  for(i in seq(nrow(dt_racesList))) {
    
    
    i_date = as.character(dt_racesList[i]$date_ymd)
    
    
    list_export <- list(list(date_ymd = i_date,
                             date_display = dt_racesList[i]$date_display,
                             season = dt_racesList[i]$season,
                             season_display = dt_racesList[i]$season_display,
                             extraNote = dt_racesList[i]$extraNote,
                             
                             raceStats = dt_race_stats[date_ymd==i_date] |> as.list(),
                             
                             tabData = list_teamsManual[[i_date]],
                             marshalling = unlist(unlist(dt_marshallingPrep2[date_ymd==i_date]$marshalling,recursive = FALSE),recursive = FALSE),
                             newcomers = unlist(unlist(dt_newcomersPre2[date_ymd==i_date]$milestones,recursive = FALSE),recursive = FALSE),
                             milestones = unlist(unlist(dt_milestonesPre2[date_ymd==i_date]$milestones,recursive = FALSE),recursive = FALSE),
                             
                             plot2 = list(data = dt_plotPrep_long3[date_ymd==i_date],
                                          distances = dt_plotPrepDistances[date_ymd==i_date,.(distanceID, distanceDisplay)],
                                          categories = dt_plotPrepCategories[date_ymd==i_date, .(distanceID, Category)],
                                          annotations = dt_annotatopnPrep[date_ymd==i_date, .(distanceID, Category, annotations)],
                                          layoutAxes = dt_layoutAxes[date_ymd==i_date, .(distanceID, Category, xaxis, racers)]),
                             tab2 = dt_tablePrep4[date_ymd==i_date]$raceData|> unlist(recursive = FALSE) |> unname() |> unlist(recursive = FALSE),
                             pointsTab = dt_pointsTablePrep[date_ymd==i_date]$pointsData
    )
    )
    
    json_prep <- list_export |> 
      toJSON(pretty = FALSE)
    
    write(json_prep, file.path(path_raceData, glue("{i_date}.json", i_date = i_date)))
    
  }
  
  
}
