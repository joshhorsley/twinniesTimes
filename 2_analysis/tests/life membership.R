dt_members <- dt_dbReadTable(conn, "members")
dt_totalRacesOverall <- dt_dbReadTable(conn, "totalRacesOverall")
dt_committee <- dt_dbReadTable(conn, "committee")

dt_totalRacesDate <- dt_dbReadTable(conn, "totalRacesDate")


n_races <- 500
n_committee <- 3
date_recent <- "2025-01-01"

dt_races_satisfy <- dt_totalRacesOverall[races_all >= n_races, .(id_member, races_all)]

dt_committee_satisfy <-  dt_committee[,.N, by = id_member][N >= n_committee]


dt_active_recent <- dt_totalRacesDate[!is.na(races_all) & date_ymd >= date_recent, .(date_latest = date_ymd[.N]), by = id_member]


dt_races_satisfy[dt_committee_satisfy, on = .(id_member), committee := i.N]

dt_races_satisfy[!is.na(committee)]
dt_races_satisfy[!is.na(committee) & id_member %in% dt_active_recent$id_member]
