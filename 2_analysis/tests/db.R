dbGetInfo(conn)

dbListTables(conn)

dt_members_check <- dt_dbReadTable(conn, "members")
dt_dbReadTable(conn, "memberChips")
dt_dbReadTable(conn, "memberChipLatest")
dt_dbReadTable(conn, "seasons")
dt_dbReadTable(conn, "races")
dt_raceResults_check <- dt_dbReadTable(conn, "raceResults")
dt_dbReadTable(conn, "twintownMemberships")
dt_dbReadTable(conn, "committee")
dt_dbReadTable(conn, "awards")
dt_dbReadTable(conn, "distances")
dt_totalRacesSeason_check <- dt_dbReadTable(conn, "totalRacesSeason")
dt_dbReadTable(conn, "totalRacesOverall")
dt_dbReadTable(conn, "totalRacesDate")
dt_dbReadTable(conn, "timesBestPoints")
dt_registrationsCheck <- dt_dbReadTable(conn, "registrations")
dt_dbReadTable(conn, "marshalling")

dt_registrationsCheck[grepl("^Sam", Name)]