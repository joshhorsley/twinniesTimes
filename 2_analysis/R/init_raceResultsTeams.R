init_raceResultsTeams <- function(conn, path_manual) {
  
  
  dt_teams_load <- read_excel(path_manual, sheet = "teams") |> 
    as.data.table()
  
  dt_teams_load[, date_ymd := as.Date(date_ymd)]
  dt_teams_load[, total := total |> as.character() |> ymd_hms() |> format("%H:%M:%S")]
  
  dt_teams_long <- melt.data.table(dt_teams_load[!is.na(date_ymd)],
                                   id.vars = c("date_ymd","team", "rank","total"),
                                   measure.vars = patterns("bib$", "id$", "name$"),
                                   variable.name = "teamPosition",
                                   value.name = c("Bib","id_member","Name"))
  
  dt_teams_long[, teamPosition := NULL]
  setnames(dt_teams_long, c("total","rank"), c("Time","Place"))
  
  
  # Standardise times -------------------------------------------------------
  

  # express all times in seconds  
  time_cols <- c("Time")
  dt_teams_long[, (time_cols) := lapply(.SD, function(x) ifelse(x %in% c("-",""), NA,x)), .SDcols = time_cols]
  dt_teams_long[, (time_cols) := lapply(.SD, hmsOrMsToSeconds), .SDcols = time_cols]
  
  
  
  # Join seasons ------------------------------------------------------------
  
  
  dt_reaces <- dt_dbReadTable(conn, "races")
  dt_reaces[, date_ymd := as.Date(date_ymd)]
  
  dt_teams_long[dt_reaces, on = .(date_ymd), season := i.season]
  
  
  
  
  # Save --------------------------------------------------------------------
  
  
  dt_out <- dt_teams_long[id_member!="VACANT", .(date_ymd = format(date_ymd, "%Y-%m-%d"),
                                                 season,
                              id_member,
                              distanceID = "teams",
                              teamID = team,
                              TimeTotal = Time,
                              Lap1 = Time,
                              chip = Bib,
                              NameProvided = Name,
                              source = "teamsManual")]
  
  dbAppendTable(conn, "raceResults", dt_out)
  
  
}


if(FALSE) {
  
  dt_members <- dt_dbReadTable(conn, "members")
  
  
}