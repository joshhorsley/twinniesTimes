init_startTimesAndPoints <- function(conn,
                                     path_manual,
                                     cats_eligible = c("Handicap Points","Non-championship","Club Champs"),
                                     eventStartTimeExclude = c("Teams", "Club Champs")
) {
  
  
  # Load --------------------------------------------------------------------
  
  
  date_previous <- "2024-03-02"
  
  # 2023-2024 best adjusted  
  dt_previous <- read_excel(path_manual, sheet = "handicapTimesSeasonStart") |> 
    as.data.table()
  
  dt_races_new <- dt_dbReadTable(conn, "races")[date_ymd >= date_previous, .(season, date_ymd)]
  
  dt_results_sprint <- dt_dbReadTable(conn, "raceResults")[date_ymd > date_previous & distanceID=="sprint"]
  
  dt_results_nonsprint <- dbGetQuery(conn, "SELECT season, date_ymd, distanceID, id_member, Category, TimeTotal
             FROM raceResults
             WHERE season >= '2024-2025' AND NOT(distanceID IN ('sprint'))") |> 
    as.data.table()
  
  dt_marshalling <- dt_dbReadTable(conn, "marshalling")
  
  dt_racesSeason <- dt_dbReadTable(conn, "races")[season>="2024-2025"]
  
  
  
  # Prep table for time and points tracking ---------------------------------
  
  
  dt_StartPointsBest <- CJ(
    date_ymd = sort(unique(c(
      date_previous,
      dt_results_sprint$date_ymd,
      dt_results_nonsprint$date_ymd,
      dt_marshalling$date_ymd
    ))),
    id_member = sort(unique(c(
      dt_previous$id_member,
      dt_results_sprint$id_member,
      dt_results_nonsprint$id_member,
      dt_marshalling$id_member
    ))))
  
  # season
  dt_StartPointsBest[date_ymd == date_previous, season := "2023-2024"]
  dt_StartPointsBest[dt_races_new, on = .(date_ymd), season := i.season]
  
  
  # Add sprint results ------------------------------------------------------
  
  
  #  new sprint
  dt_results_sprint[, racedSprint := TRUE]
  dt_results_sprint[, timed := !is.na(TimeTotal)]
  
  dt_StartPointsBest[dt_results_sprint,
                     on = .(date_ymd, id_member),
                     `:=`(TimeTotal = i.TimeTotal,
                          Category = i.Category,
                          racedSprint = i.racedSprint,
                          timed = i.timed)]
  dt_StartPointsBest[is.na(racedSprint), racedSprint := FALSE]
  dt_StartPointsBest[is.na(TimeTotal), TimeTotal := Inf  ]
  
  
  # Calculate best adjusted time changes ------------------------------------
  
  
  dt_StartPointsBest[dt_previous,
                     on = .(season = starting_season, id_member),
                     timeBestSeason := i.BestAdjusted - 180]
  
  dt_StartPointsBest[season>"2023-2024", timeBestSeason := cummin(TimeTotal), by = .(id_member, season)]
  dt_StartPointsBest[season>"2023-2024", timeBestSeasonPrevious := shift(timeBestSeason,fill = Inf), by = .(id_member, season)]
  
  dt_bestBySeason <- dt_StartPointsBest[,.(
    timeBestSeasonAdjusted = timeBestSeason[.N] + 180),
    by = .(season,id_member)]
  setorder(dt_bestBySeason, id_member, season)
  
  
  
  dt_bestBySeason[, timeBestSeasonAdjusted_carryForward := carryBestForward(timeBestSeasonAdjusted), by = .(id_member)]
  dt_bestBySeason[, seasonNext := shift(season,n = -1), by = .(id_member)]
  
  
  # time to use for current handicap
  dt_StartPointsBest[dt_bestBySeason, on = .(season = seasonNext, id_member),
                     timeBestSeasonAdjusted_carryForward := i.timeBestSeasonAdjusted_carryForward]
  dt_StartPointsBest[, timeBestPreviousUse := min(timeBestSeasonAdjusted_carryForward, timeBestSeasonPrevious),
                     by = .(id_member, date_ymd)]
  
  # Next start time ---------------------------------------------------------
  
  
  # This season
  dt_StartPointsBest[, nextStartThisSeason := min(timeBestSeasonAdjusted_carryForward, timeBestSeason), by = .(id_member, date_ymd)]
  
  # Next season
  dt_StartPointsBest[, hasAnyTimedSprintSeason := any(is.finite(timeBestSeason)), by = .(id_member, season)]
  dt_StartPointsBest[, nextStartNextSeason := ifelse(hasAnyTimedSprintSeason,
                                                     timeBestSeason+180,
                                                     timeBestSeasonAdjusted_carryForward),
                     by = .(id_member, season)]
  
  
  # Map next race -----------------------------------------------------------
  
  
  dt_racesSeason[, racedSprint := date_ymd %in% dt_StartPointsBest[(racedSprint)]$date_ymd]
  dt_racesSeason[, isHandicapped := special_event %notin% eventStartTimeExclude]
  
  dt_racesSeason[, ind_next := nexthandicapped(racedSprint, isHandicapped)]
  dt_racesSeason[, date_ymd_next := dt_racesSeason$date_ymd[ind_next]]
  dt_racesSeason[, season_next := dt_racesSeason$season[ind_next]]
  
  dt_racesSeason[, islaterSeason := season_next > season]
  
  dt_StartPointsBest[dt_racesSeason, on = .(date_ymd), 
                     `:=`(date_ymd_next = i.date_ymd_next,
                          islaterSeason = i.islaterSeason
                          )]
  
  dt_StartPointsBest[, nextStartUse := ifelse(islaterSeason, nextStartNextSeason, nextStartThisSeason)]
  
  
  # Time differences and handicap points ------------------------------------
  
  
  # current time subtract previous best adjusted to get if there is a decrease
  dt_StartPointsBest[season>"2023-2024", comparableTimes := is.finite(TimeTotal) & is.finite(timeBestPreviousUse)]
  dt_StartPointsBest[(racedSprint) & (comparableTimes), timeDiff := TimeTotal - timeBestPreviousUse]
  
  # award handicap points in category to up to 15 greatest improvement
  dt_StartPointsBest[, handicapPoints_eligible := (racedSprint) & Category %in% cats_eligible  & (comparableTimes)]
  dt_StartPointsBest[(handicapPoints_eligible), timeDiffRank := frank(timeDiff, ties.method = "min"), by = .(date_ymd)]
  dt_StartPointsBest[, handicapPoints_give := (handicapPoints_eligible) & timeDiffRank < 16L & timeDiff < 0L]
  dt_StartPointsBest[, points_handicap_awarded := ifelse(handicapPoints_give, 16L - timeDiffRank,0L)]
  
  
  # Participation points ----------------------------------------------------
  
  
  # sprint races
  dt_StartPointsBest[, points_participation_awarded := ifelse(racedSprint, 15L, 0L) ]
  
  # non-sprint races
  # 2024-2025
  dt_results_nonsprint[season=="2024-2025",
                       points_participation_awarded := ifelse(distanceID %in% c("doubledistance", "palindrometri","riderun"), 30L, 0L)]
  dt_results_nonsprint[season>="2025-2026",
                       points_participation_awarded := ifelse(distanceID %in% c("doubledistance", "palindrometri","teams","longtri"), 30L, 0L)]
  
  dt_StartPointsBest[dt_results_nonsprint, on = .(date_ymd, id_member), points_participation_awarded := i.points_participation_awarded]
  
  # marshaling
  dt_marshalling[dt_races_new, on = .(date_ymd), season := i.season]
  
  # starting 2025-2026 30 points for first two marshaling per season, then 15
  dt_marshalling[, marshal_ordinal := seq(.N), by = .(season, id_member)]
  
  dt_marshalling[season=="2024-2025", points_marshal := 0]
  dt_marshalling[season >= "2025-2026", points_marshal := ifelse(marshal_ordinal < 3, 30, 15)]
  
  dt_StartPointsBest[dt_marshalling, on = .(date_ymd, id_member), points_marshal_awarded := i.points_marshal]
  dt_StartPointsBest[is.na(points_marshal_awarded), points_marshal_awarded := 0]
  
  # override sprint participation with marshaling points
  dt_StartPointsBest[points_participation_awarded < points_marshal_awarded, points_participation_awarded := points_marshal_awarded]
  
  
  # Total and rank ----------------------------------------------------------
  
  
  dt_StartPointsBest[, points_all_awarded := points_handicap_awarded + points_participation_awarded]
  
  # running totals
  dt_StartPointsBest[, c("points_all_total",
                         "points_handicap_total",
                         "points_particiation_total") :=
                       lapply(.SD, cumsum),
                     .SDcols = c("points_all_awarded",
                                 "points_handicap_awarded",
                                 "points_participation_awarded" ),
                     by = .(id_member, season)]
  
  # rank overall
  dt_StartPointsBest[points_all_total!= 0, rank_all_total := frank(-points_all_total, ties.method = "min"), by = .(date_ymd, season)]
  
  
  # Save --------------------------------------------------------------------
  
  dbAppendTable(conn, "timesBestPoints", dt_StartPointsBest)
  
  
}