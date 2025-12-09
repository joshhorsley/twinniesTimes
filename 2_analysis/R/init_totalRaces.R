init_totalRaces <- function(conn, path_manual) {
  
  
  # pre-webscorer totals by season ------------------------------------------
  
  
  dt_totals_manual_wide <- read_excel(path_manual, sheet = "members", guess_max = 2500) |>
    as.data.table()
  
  dt_totals_old <- melt.data.table(dt_totals_manual_wide, id.vars = c("id_member"),
                                   measure.vars = patterns("^[0-9]"),
                                   variable.name = "season",
                                   value.name = "races_full", na.rm = TRUE)
  
  
  
  # webscorer epoch totals --------------------------------------------------
  
  
  dt_races_new <- dbGetQuery(conn, "SELECT season, date_ymd, id_member, distanceID
                            FROM raceResults") |> 
    as.data.table()
  
  dt_totals_new_wide <-  dt_races_new[, .(races = .N), by = .(id_member,distanceID, season)] |> 
    dcast.data.table(id_member + season ~ distanceID,
                     fill = 0,
                     value.var = "races")
  
  dt_totals_new_wide[, races_full := as.integer(sprint + doubledistance + palindrometri +longtri)]
  
  
  # Totals by season --------------------------------------------------------
  
  
  # calculate
  dt_totals_by_season <- rbindlist(
    list(
      dt_totals_old,
      dt_totals_new_wide
    ),
    use.names = TRUE,fill = TRUE)
  
  # drop NAs
  distances_to_remove_NAs <- setdiff(names(dt_totals_by_season), c("id_member","season","races_full"))
  dt_totals_by_season[, (distances_to_remove_NAs) := lapply(.SD, function(x) ifelse(is.na(x),0,x)), .SDcols = distances_to_remove_NAs]
  
  # complicated row add initially done to avoid NAs
  components_for_races_all <- setdiff(names(dt_totals_by_season),
                                      c("id_member","season", "sprint","doubledistance","longtri","palindrometri"))
  
  dt_totals_by_season[, races_all := rowSums(.SD, na.rm = TRUE), .SDcols = components_for_races_all]
  
  setorder(dt_totals_by_season, id_member, season)
  
  
  # save
  dbAppendTable(conn, "totalRacesSeason", dt_totals_by_season)
  
  
  
  # Totals by race ----------------------------------------------------------
  
  
  
  # marginal race counts for each type and summaries
  dt_total_by_date_prep <-  dt_races_new[, .(races = .N), by = .(id_member,distanceID, season, date_ymd)]
  
  cols_full <- c("sprint","doubledistance", "palindrometri", "longtri")
  dt_total_by_date_prep <- dt_total_by_date_prep[distanceID %in% cols_full, races_full := 1]
  
  dt_totals_by_date <-  dt_total_by_date_prep |> 
    dcast.data.table(id_member + season + date_ymd + races_full ~ distanceID,
                     fill = NA,
                     value.var = "races")
  
  dt_totals_by_date[, races_all := 1L]
  
  
  # do cumulative sum
  cols <- setdiff(names(dt_totals_by_date), c("id_member","season","date_ymd"))
  dt_totals_by_date[, (cols) := lapply(.SD, cumsum_omitNA), .SDcols = cols, by = .(id_member)]
  
  
  # add previous total
  dt_total_pre_webscorer <- dt_totals_old[, .(races_full_previous = sum(races_full)), by = id_member]
  dt_totals_by_date[dt_total_pre_webscorer, on = .(id_member), races_full_previous := i.races_full_previous]
  dt_totals_by_date[!is.na(races_full), races_full := sum(races_full, races_full_previous, na.rm = TRUE), by = .(id_member, date_ymd)]
  dt_totals_by_date[!is.na(races_all), races_all := sum(races_all, races_full_previous, na.rm = TRUE) |> as.integer(), , by = .(id_member, date_ymd)]
  dt_totals_by_date[, races_full_previous:= NULL]
  
  
  # set date as character for save
  dt_totals_by_date[, date_ymd := format(as.Date(date_ymd), "%Y-%m-%d")]
  
  # save
  dbAppendTable(conn, "totalRacesDate", dt_totals_by_date)
  
  
  # Totals overall ----------------------------------------------------------
  
  
  distancse_to_sum <- setdiff(names(dt_totals_by_season), c("id_member","season"))
  
  dt_totals_all <- dt_totals_by_season[, lapply(.SD, sum, na.rm = TRUE), .SDcols = distancse_to_sum, by = id_member ]
  
  # save
  dbAppendTable(conn, "totalRacesOverall", dt_totals_all)
  
  
  
  # Update total races metric ---------------------------------------------
  
  
  dt_totalRacesMetricUpdate <- dbGetQuery(conn, "SELECT id_member
                            FROM members
             WHERE totalRacesMetric IS NULL") |> 
    as.data.table()
  
  dt_totalRacesMetricUpdate[dt_totals_all, on = .(id_member), `:=`(races_full = i.races_full,
                                                                   races_all = i.races_all)]
  
  dt_totalRacesMetricUpdate[, raceMetricAuto := ifelse(races_all > 2*races_full, "all", "full")]
  
  
  raceMetricUpdateQuery <- function(updateValue, id_member_update) {
    
    updateMemberIds <- glue("'{x}'", x = id_member_update) |> 
      paste0(collapse = ",")
    
    glue("UPDATE members SET totalRacesMetric='{updateValue}' WHERE id_member IN ({updateMemberIds});") |> 
      as.character()
  }
  
  dt_updateQueries <- dt_totalRacesMetricUpdate[!is.na(raceMetricAuto),
                                                .(updateQuery = raceMetricUpdateQuery(raceMetricAuto[1], id_member)),
                                                by = raceMetricAuto]
  
  
  dt_updateQueries[, out := dbExecute(conn, updateQuery), by = updateQuery]
  
  return(0)
  
}
