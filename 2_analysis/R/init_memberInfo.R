# Members

init_members <- function(conn, path_manual) {
  
  # more guesses to make sure the very sparse totalRacesMetric is correctly typed
  dt_members <- read_excel(path_manual,sheet = "members", guess_max = 3000) |> 
    as.data.table()
  
  dt_members[, name_display  := glue::glue('{name_first} {name_last}',
                                           name_first = name_first,
                                           name_last = name_last)]
  
  dt_members[is.na(noLongerRacing), noLongerRacing:= FALSE]

  dbAppendTable(conn, "members", dt_members[order(id_member), .(id_member,
                                                                name_last,
                                                                name_first,
                                                                name_display,
                                                                noLongerRacing,
                                                                totalRacesMetric,
                                                                twintownsMembershipID = as.integer(twintownsMembershipID))])
}

# Chips

init_membersChips <- function(conn, path_manual) {
  
  
  dt_memberChips <- read_excel(path_manual, sheet = "memberChip") |> 
    as.data.table()
  
  dt_memberChips[, date_assigned := as.Date(date_assigned)]
  
  dbAppendTable(conn, "memberChips",
                dt_memberChips[chip !="", .(chip,
                                            date_assigned = format(date_assigned, "%Y-%m-%d"),
                                            id_member)])
}


init_memberChipLatest <- function(conn) {
  
  dt_memberChips <- dt_dbReadTable(conn, "memberChips")
  
  dt_memberChipLatest <- dt_memberChips[order(chip, date_assigned),
                                        .(id_member = id_member[.N], date_assigned = date_assigned[.N]), by = chip][
                                          order(date_assigned),
                                          .(chip = chip[.N]), by = id_member
                                        ][order(id_member)]
  
  dbAppendTable(conn, "memberChipLatest",dt_memberChipLatest)
  
}