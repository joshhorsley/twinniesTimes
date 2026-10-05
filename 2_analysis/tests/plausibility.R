conn <- dbConnect(RSQLite::SQLite(), paths$db)

dt_raceResults <- dt_dbReadTable(conn, "raceResults")

setorder(dt_raceResults, id_member, date_ymd)


date_max <- dt_raceResults$date_ymd |> max()



dt_raceResults[, raced_current := (date_ymd==date_max) |> any(), by = .(id_member)]
dt_raceResults[(raced_current), distance_now := distanceID[which(date_ymd==date_max)], by = .(id_member) ]
dt_raceResults[, is_current_distance := distance_now ==distanceID]



cols_check <- c("TimeTotal", paste0("Lap", 1:5))

dt_compare_times <- 
  dt_raceResults[
    date_ymd >="2024-2025" & (raced_current) & (is_current_distance),
      lapply(.SD, min, na.rm = TRUE),
    .SDcols = cols_check,
    by = .(distanceID, id_member, is_max_date = date_ymd ==date_max )]

dt_compare_times[, time_source := fifelse(is_max_date, "current", "previous_best")]


# Prep plausible absolute values ------------------------------------------


times_plausible_min <- list(
  "sprint" = list(
    "laps" = c(7, 24, 15),
    "total" = 50
  ),
  "tempta" = list(
    "laps" = c(4.5, 15, 8),
    "total" = 30
  )
)


dt_plausible_mins <- times_plausible_min |> lapply(function(x) {
  dt_out <- x$laps |> t() |> as.data.table()
  setnames(dt_out, paste0("V",1:5), paste0("Lap", 1:5),skip_absent = TRUE)
  
  dt_out[, TimeTotal := x$total]
}) |> 
  rbindlist(idcol = "distanceID") |> 
  melt.data.table(
    id.vars = "distanceID",
    variable.name = "part",
    value.name = "plausible_mins_abs",
    variable.factor = FALSE
  )


# Compare -----------------------------------------------------------------


dt_latest_long <- 
  dt_compare_times |> 
  melt.data.table(
    id.vars = c("distanceID", "id_member", "time_source"),
    variable.name = "part",
    value.name = "actual_seconds",
    variable.factor = FALSE
  ) |> 
  dcast.data.table(
    formula = distanceID + id_member + part ~ time_source,
    value.var = "actual_seconds"
  )
dt_latest_long[, current_mins := (current/60) |> round(1)]
dt_latest_long[, current := NULL]
dt_latest_long[, previous_best_mins := (previous_best/60) |> round(1)]
dt_latest_long[, previous_best := NULL]


dt_latest_long[dt_plausible_mins, on = .(distanceID, part), plausible_mins_abs := i.plausible_mins_abs]

dt_latest_long[, implausible_time_absolute := current_mins < plausible_mins_abs]

dt_latest_long[, time_change_mins := current_mins - previous_best_mins]
dt_latest_long[time_change_mins < 0, time_change_percent := (time_change_mins /previous_best_mins * 100) |> round(0) ]
dt_latest_long[, implausible_improve := time_change_mins/previous_best_mins > 0.2]


# Checks ------------------------------------------------------------------


dt_latest_long[(implausible_time_absolute) ]
dt_latest_long[time_change_mins < 0 ][order(time_change_percent)]
