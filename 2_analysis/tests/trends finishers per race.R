dt_totalRacesSeason <- dt_dbReadTable(conn, "totalRacesSeason")
dt_races <- dt_dbReadTable(conn, "races")
dt_raceResults <- dt_dbReadTable(conn, "raceResults")

dt_raceCountPerSeason <- dt_raceResults[,.(n_racesWithResults = length(unique(date_ymd))), by = season]

dt_seasonTrends <- dt_totalRacesSeason[, .(finishers = sum(races_all)), by = season][order(season)]


dt_seasonTrends[dt_raceCountPerSeason, on = .(season), n_racesWithResults := i.n_racesWithResults]


dt_seasonTrends[is.na(n_racesWithResults), n_racesWithResults := 26]

dt_seasonTrends[, finishersPerRace := finishers/n_racesWithResults]



plot(
     dt_seasonTrends$finishersPerRace,
     type= "l",
     ylim = c(0, max(dt_seasonTrends$finishersPerRace))
     )
# dt_races[is.na(cancelled_reason), .N, by = season][season < "2024-2025"]



