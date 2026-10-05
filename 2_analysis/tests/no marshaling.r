dt_races <- dt_dbReadTable(conn, "races")

dates_season <- dt_races[season=="2024-2025"]$date_ymd

dt_marshal_all <- dt_dbReadTable(conn, "marshalling")

dt_marshalled <- dt_marshal_all[date_ymd %in% dates_season, .N, by = id_member]


dt_raceResults <- dt_dbReadTable(conn, "raceResults")


dt_compare <- dt_raceResults[date_ymd %in% dates_season, .(races = .N), by = id_member]


dt_compare[dt_marshalled, on = .(id_member), marshalled := i.N]


dt_members <- dt_dbReadTable(conn, "members")

dt_compare[dt_members, on = .(id_member), name_display := i.name_display]

dt_compare[is.na(marshalled)][order(-races), .(Name = name_display, `Races 2024/25` = races)]
