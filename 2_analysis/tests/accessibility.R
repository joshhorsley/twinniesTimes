dt_raceResults <- dt_dbReadTable(conn, "raceResults")


access_distances <- c("aquabike","swimrun","riderun", "doubleaquabike")
access_distances <- c("aquabike","swimrun", "doubleaquabike")

dt_raceResults[distanceID=="aquabike"][1]
dt_raceResults[, is_access := distanceID %in% access_distances]

dt_accessible_totals <- dt_raceResults[date_ymd>="2022-11-12"][, .(N= .N, is_access = is_access[1]), by = distanceID]

dt_accessible_totals[, frac := N/sum(N)]


dt_access_frac <- dt_accessible_totals[, .(N = sum(N)), by = is_access]
dt_access_frac[, frac := N/sum(N)]

dt_accessible_participants <- dt_raceResults[date_ymd>="2022-11-12" & (is_access)][ ,.N, by = id_member]

dt_accessible_participants[, .N]
