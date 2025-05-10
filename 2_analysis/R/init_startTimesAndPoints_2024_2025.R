init_startTimesAndPoints_2024_2025 <- function(conn,
                                               path_manual,
                                               cats_eligible = c("Handicap Points","Non-championship","Club Champs")
) {
  
  
  # Load --------------------------------------------------------------------
  
  
  dt_previous <- read_excel(path_manual, sheet = "handicapTimesSeasonStart") |> 
    as.data.table()
  
  dt_results_2024_2025 <- dbGetQuery(conn, "SELECT date_ymd, id_member,Category, TimeTotal
             FROM raceResults
             WHERE season='2024-2025' AND distanceID='sprint'") |> 
    as.data.table()
  
  dt_results_2024_2025[, raced := TRUE]
  dt_results_2024_2025[, timed := !is.na(TimeTotal)]
  
  # dt_results_2024_2025 <- dt_results_2024_2025[FALSE]
  
  
  # Load double for participation only --------------------------------------
  
  
  # Double distance for double points
  dt_results_double2024_2025 <- dbGetQuery(conn, "SELECT date_ymd, distanceID,id_member,Category, TimeTotal
             FROM raceResults
             WHERE season='2024-2025' AND distanceID IN ('doubledistance', 'palindrometri','riderun')") |> 
    as.data.table()
  dt_results_double2024_2025[, points_part_double := 30L]
  
  
  # Process -----------------------------------------------------------------
  
  
  # create week 0 for previous season's adjusted time
  date_first_race <- dbGetQuery(conn, "SELECT MIN(date_ymd) AS date_min FROM races WHERE season='2024-2025'")$date_min |> 
    as.Date()
  # date_join <- "2024-09-01"
  date_join <- (date_first_race - 7) |> format("%Y-%m-%d")
  
  dt_previous[, date_ymd_join := date_join]
  
  
  dt_StartPointsBest <- CJ(date_ymd = sort(c(date_join,unique(c(dt_results_2024_2025$date_ymd, dt_results_double2024_2025$date_ymd)))),
                           id_member = unique(c(dt_previous$id_member, dt_results_2024_2025$id_member, dt_results_double2024_2025$id_member)))
  
  setorder(dt_StartPointsBest, id_member, date_ymd)
  # id_member = unique(dt_results_2024_2025$id_member))
  
  
  dt_StartPointsBest[dt_previous, on = .(id_member, date_ymd = date_ymd_join), TimeTotal := i.BestAdjusted]
  dt_StartPointsBest[dt_results_2024_2025,
                     on = .(id_member, date_ymd),
                     `:=`(TimeTotal = i.TimeTotal,
                          Category = i.Category,
                          raced = i.raced,
                          timed = i.timed)]
  dt_StartPointsBest[is.na(raced), raced := FALSE]
  
  
  dt_StartPointsBest[is.na(TimeTotal), TimeTotal := Inf  ]
  dt_StartPointsBest[, timeBest := cummin(TimeTotal), by = .(id_member)]
  dt_StartPointsBest[, timeBestPrevious := shift(timeBest), by = .(id_member)]
  
  dt_StartPointsBest[, hasAnyTimedResults := is.finite(timeBest[.N]), by = id_member]
  
  
  #drop previous season rows
  # dt_StartPointsBest <- dt_StartPointsBest[date_ymd != date_join]
  dt_StartPointsBest[, isWeekZero := date_ymd == date_join]
  
  # current time subtract previous time to get if there is a decrease
  dt_StartPointsBest[, comparableTimes := is.finite(timeBest) & is.finite(timeBestPrevious)]
  dt_StartPointsBest[(raced) & (comparableTimes), timeDiff := TimeTotal - timeBestPrevious]
  
  
  # award handicap points in category to up to 15 greatest improvement
  dt_StartPointsBest[, handicapPoints_eligible := (raced) & Category %in% cats_eligible  & (comparableTimes)]
  dt_StartPointsBest[(handicapPoints_eligible), timeDiffRank := frank(timeDiff, ties.method = "min"), by = .(date_ymd)]
  dt_StartPointsBest[, handicapPoints_give := (handicapPoints_eligible) & timeDiffRank < 16L & timeDiff < 0L]
  dt_StartPointsBest[, points_handicap_awarded := ifelse(handicapPoints_give, 16L - timeDiffRank,0L)]
  
  
  # participation points
  dt_StartPointsBest[, points_participation_awarded := ifelse(raced, 15L, 0L) ]
  dt_StartPointsBest[dt_results_double2024_2025, on = .(date_ymd, id_member), points_participation_awarded := i.points_part_double]
  
  dt_StartPointsBest[, points_all_awarded := points_handicap_awarded + points_participation_awarded]
  
  # running totals
  dt_StartPointsBest[, c("points_all_total",
                         "points_handicap_total",
                         "points_particiation_total") :=
                       lapply(.SD, cumsum),
                     .SDcols = c("points_all_awarded",
                                 "points_handicap_awarded",
                                 "points_participation_awarded" ),
                     by = .(id_member)]
  
  # rank overall
  dt_StartPointsBest[!(isWeekZero) & points_all_total!= 0, rank_all_total := frank(-points_all_total, ties.method = "min"), by = .(date_ymd)]
  
  
  # Save --------------------------------------------------------------------
  
  
  dt_StartPointsBest[, season := "2024-2025"]  
  dbAppendTable(conn, "timesBestPoints", dt_StartPointsBest)
  
}

if(FALSE) {
  
  dt_StartPointsBest[id_member=="bartlett_adrian"]
  dt_StartPointsBest[id_member=="pearce_clive"]
  
  dt_StartPointsBest[date_ymd=="2024-10-05" & points_all_total!= 0][order(rank_all_total)]
  
  dt_StartPointsBest[id_member=="temperly_aled"]
}