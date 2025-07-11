

if(FALSE) {
  
  path_source <- pathsWebsiteData$source
  path_MemberData <- pathsWebsiteData$memberData
  recentSeasons <-  1L
  
  
  listviewer::jsonedit(json_memberData)
  
}

# data for website --------------------------------------------------------


prepJsonMemberData <- function(conn,
                               path_source,
                               path_MemberData,
                               recentSeasons = 2L) {
  
  
  # Load and common ---------------------------------------------------------
  
  
  dt_members <-  dt_dbReadTable(conn, "members")
  dt_memberChipLatest <- dt_dbReadTable(conn, "memberChipLatest")
  dt_totalRacesOverall <-  dt_dbReadTable(conn, "totalRacesOverall")
  
  dt_committee <- dt_dbReadTable(conn, "committee")
  
  dt_races <- dt_dbReadTable(conn,"races")
  
  dt_raceResults <- dt_dbReadTable(conn, "raceResults")
  
  seasonRecentCutoff <- dt_dbReadTable(conn, "seasons")[.N-(recentSeasons-1)]
  
  dt_marshalling <- dt_dbReadTable(conn, "marshalling")
  
  
  # Recent ------------------------------------------------------------------
  
  
  dt_memberRecent <- dt_raceResults[, .(memberRecent = max(season) >= seasonRecentCutoff), by = .(id_member)]
  
  
  ## total races -------------------------------------------------------------
  
  
  dt_distances <- dt_dbReadTable(conn, "distances")
  
  dt_distanceParts <- dt_distances # remove this?
  
  dt_distanceParts <- dt_distances[, .(
    part = trimws(unlist(strsplit(parts,split = ";")))
  ), by = .(distanceID)]
  dt_distanceParts[, lap := as.character(glue("Lap{lapNumber}", lapNumber = seq(.N))), by = distanceID]
  

    ## members -----------------------------------------------------------------
  
  
  # member list
  dt_members[order(id_member), .(value = id_member,
                                 label = name_display)][order(value)] |> 
    jsonlite::toJSON() |> 
    write(file.path(path_source, "membersListFlat.json"))
  
  
  dt_members[dt_memberChipLatest, on = .(id_member), chipLatest := i.chip ]
  
  dt_members[dt_memberRecent, on = .(id_member), memberRecent := i.memberRecent]
  dt_members[is.na(memberRecent), memberRecent := FALSE]
  dt_members[, memberRecentCat := ifelse(memberRecent, "Recent","Earlier")]
  
  # member list heirarchical
  path_memberListHierarchy <- file.path(path_source, "memberListHierarchy.json")
  
  dt_members[order(id_member), .(members = list(
    data.table(id_member, name_display)
  )), by = .(memberRecentCat)][order(-memberRecentCat)] |> 
    toJSON() |> 
    write(path_memberListHierarchy)
  
  
  
  # Prep committee ----------------------------------------------------------
  
  
  dt_committeePrep <- dt_committee[, .(committee = list(data.table(count = .N,
                                                                   details = list(data.table(role = role,
                                                                                             season = season))))), by = id_member]
  
  
  # Prep races --------------------------------------------------------------
  
  
  ## Prep races cancellations and off-season ---------------------------------
  
  
  # off-seson
  dt_offSeasons <- dt_races[, .(date_start = date_ymd[1],
                                date_end = date_ymd[.N]), by = season]
  
  dt_offSeasons[, date_endPrevious := shift(date_end,1)]
  dt_offSeasons[, `:=`(
    date_offSeasonStartDisplay = as.character(as.Date(date_endPrevious) + 5),
    date_offSeasonEndDisplay = as.character(as.Date(date_start) - 5)
  ), by = season]
  
  # cancellations
  dt_cancellations <- dt_races[!is.na(cancelled_reason), .(
    date_startDisplay = as.character(as.Date(date_ymd) + 3),
    date_endDisplay = as.character(as.Date(date_ymd) -3),
    season, 
    cancelled_reason), by = date_ymd]
  
  ## time ranges
  
  #' for each person,
  #' - always include most recent 6 weeks
  #' - only include seasons they have races for
  
  dt_timeRangesPrep <- dt_raceResults[,.(temp = 1), by = .(id_member, season)]
  dt_timeRangesPrep[, temp := NULL]
  
  dt_timeRangesPrepSeasons <- dt_races[, .(dateRange = list(c(
    as.character(as.Date(date_ymd[1]) - 5),
    as.character(as.Date(date_ymd[.N]) + 5)
  ))), by = season]
  
  dt_timeRangesPrep[dt_timeRangesPrepSeasons, on = .(season), dateRange := i.dateRange]
  
  
  dt_timeRangesPrepRecent <- dt_raceResults[, .(season="recent",
                                                dateRange = list(c(
                                                  as.character(as.Date(max(date_ymd))-7*5),
                                                  as.character(as.Date(max(date_ymd)) + 12)
                                                ))), by = .(id_member)]
  
  dt_timeRangesPrepCombined <- rbindlist(list(dt_timeRangesPrepRecent, dt_timeRangesPrep))
  
  dt_timeRangeOut <- dt_timeRangesPrepCombined[, .(season_ranges = list(c(dateRange) |> setNames(season))), by = id_member]
  
  # seasons 2024-2025 onwards for dynamic xRangeSelection
  dt_timeRangesPrepCombined[season=="recent", season_label := "Recent"]
  dt_timeRangesPrepCombined[season!="recent", season_label := seasonNice(season)]
  
  dt_timeRangeOptions1 <- dt_timeRangesPrepCombined[season >= "2024-2025" | season=="recent", .(xRangeOptions = list(list(
    label = season_label,
    value = season
    ))), by = .(id_member, season)]
  dt_timeRangeOptions2 <- dt_timeRangeOptions1[, .(xRangeOptions = list(list(xRangeOptions))), by = id_member]
  
  dt_timeRangeOut[dt_timeRangeOptions2, on = .(id_member), xRangeOptions := i.xRangeOptions]
  
  
  ## race types ------------------------------------------------------------
  
  
  dt_raceTypePrep <- dt_raceResults[season >= "2024-2025", .(distanceID = unique(distanceID)), by = id_member]
  dt_raceTypePrep[dt_distances, on = .(distanceID), distanceDisplay := i.distanceDisplay]
  
  dt_raceTypes <- dt_raceTypePrep[, .(raceType = list(list("value" = distanceID,
                                                           "label" = distanceDisplay))), by = .(id_member, distanceID)]
  dt_raceTypes2 <- dt_raceTypes[, .(raceType2 = list(list(raceType)) ), by = id_member]
  
  
  ## race data ------------------------------------------------------------------
  
  
  dt_raceDataPrep <- dt_raceResults[season >= "2024-2025" & !is.na(TimeTotal)] |> 
    melt.data.table(id.vars = c("season","date_ymd","id_member","distanceID","Category","TimeTotal"),
                    measure.vars = patterns("Lap"),
                    variable.name = "lap",
                    value.name = "lapLength",
                    variable.factor = FALSE)
  
  dt_raceDataPrep[, lapCumSum := cumsum(lapLength), by = .(id_member, date_ymd)]
  dt_raceDataPrep[, lapStart := shift(lapCumSum,fill = 0), by = .(id_member, date_ymd)]
  dt_raceDataPrep[!is.na(lapLength), isLastLap := c(rep(FALSE, .N-1), TRUE), by = .(id_member, date_ymd)]
  
  dt_raceDataPrep[dt_distanceParts, on = .(distanceID, lap), part := i.part]
  dt_raceDataPrep[dt_distances, on = .(distanceID), distanceDisplay := i.distanceDisplay]
  
  dt_raceDataPrep2 <- dt_raceDataPrep[!is.na(lapLength), .(barData = list(list(
    "x" = as.character(date_ymd),
    "base" = lapStart,
    "y" = lapLength,
    "distanceID" = distanceID,
    "distanceDisplay" = distanceDisplay,
    "isLastLap" = isLastLap,
    part = part[1],
    partDisplay =  tools::toTitleCase(part[1]),
    "dateNice" = toNiceDate(date_ymd),
    
    TimeTotal = seconds_to_hms_simple(TimeTotal),
    lapLength = seconds_to_hms_simple(lapLength)
  )
  )), by = .(id_member, lap, distanceID)]
  
  
  dt_raceDataPrep3 <- dt_raceDataPrep2[, .(barDataList = list(barData)), by = .(id_member)]
  
  
  ## untimed results ------------------------------------------------------------------
  
  
  dt_racePrepManual <- dt_raceResults[season >= "2024-2025" & source=="manualParticipation"]
  
  dt_racePrepManual[dt_distances, on = .(distanceID), distanceDisplay := i.distanceDisplay]
  
  
  dt_raceDataPrepManual2 <- dt_racePrepManual[, .(barData = list(list(
    "x" = as.character(date_ymd),
    "distanceID" = distanceID,
    "distanceDisplay" = distanceDisplay,
    "dateNice" = toNiceDate(date_ymd)
    
  ))), by = .(id_member, distanceID)]
  
  dt_raceDataPrepManual3 <- dt_raceDataPrepManual2[, .(barDataList = list(barData)), by = .(id_member)]
  
  
  ## marshalling  ------------------------------------------------------------------
  
  
  dt_marshallingPrep <- dt_marshalling[, .(marshalling = list(list(
    "x" = as.character(date_ymd),
    "dateNice" = toNiceDate(date_ymd)
    
  ))), by = .(id_member, date_ymd)]
  
  dt_marshallingPrep2 <-  dt_marshallingPrep[, .(marshallingList = list(marshalling)), by = .(id_member)]
  
  
  ## combine -----------------------------------------------------------------
  
  
  dt_out_plot <- dt_raceResults[, .(races = .N), by = id_member]
  
  dt_out_plot[dt_timeRangeOut, on = .(id_member), `:=`(season_ranges = i.season_ranges,
                                                       xRangeOptions = i.xRangeOptions)]
  dt_out_plot[dt_raceTypes2, on = .(id_member), raceType := i.raceType2]
  dt_out_plot[dt_raceDataPrep3, on = .(id_member), barDataList := i.barDataList]
  dt_out_plot[dt_raceDataPrepManual3, on = .(id_member), barDataManualList := i.barDataList]
  dt_out_plot[dt_marshallingPrep2, on = .(id_member), marshallingList := i.marshallingList]
  
  dt_out_plot[, plot := list(list(list(
    shapesOffseason = list(dt_offSeasons[-1]),
    shapesCancelled = list(dt_cancellations),
    season_ranges = unlist(season_ranges, recursive = FALSE),
    xRangeOptions = unlist(xRangeOptions, recursive = FALSE),
    raceType = unlist(raceType, recursive = FALSE),
    barData = unlist(barDataList, recursive = FALSE),
    barDataManual = unlist(barDataManualList, recursive = FALSE),
    marshalling = unlist(marshallingList, recursive = FALSE)
    
  ))), by = id_member]
  
  
  # Member data -------------------------------------------------------------
  
  
  dt_membersData <- copy(dt_members)
  
  dt_membersData[dt_memberChipLatest, on = .(id_member), chipLatest := i.chip ]
  dt_membersData[dt_totalRacesOverall, on = .(id_member), `:=`(racesFull= races_full,
                                                               racesTotal = races_all) ]
  
  dt_membersData[dt_committeePrep, on = .(id_member), `:=`(committee = i.committee)]
  
  dt_membersData[dt_out_plot, on = .(id_member), `:=`(plot = i.plot)]
  
  dt_membersData[, twintownsMembershipID := NULL]
  
  
  for(i in seq(nrow(dt_membersData))) {
    
    path_save <- file.path(
      path_MemberData,
      glue::glue("{id_member}.json", id_member =  dt_membersData[i]$id_member)
    )
    
    
    dt_membersData[i] |> 
      jsonlite::toJSON(na = "null", pretty = TRUE
      ) |> 
      write(path_save)
  }
  
  
}

