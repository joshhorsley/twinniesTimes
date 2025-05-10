prepJsonCommittee <- function(conn, path_source) {
  
  
  
  # Load --------------------------------------------------------------------
  
  
  dt_committee <- dt_dbReadTable(conn, "committee")
  dt_members <- dt_dbReadTable(conn, "members")
  
  
  # Prep --------------------------------------------------------------------
  
  
  dt_committee[, row_id := seq(.N)]
  
  dt_committee[, role_group := ifelse(grepl("^Other",role),"Other",role)]
  
  dt_committee[dt_members, on = .(id_member), name_display := i.name_display]
  
  
  dt_committee[, person_list := list(list(list(name_display = name_display,
                                    id_member = id_member))), by = row_id]
  
  
  dt_committee_prep <- dcast.data.table(
    dt_committee,
    season ~ role_group,
    # value.var = c("name_display","id_member"),
    value.var = c("person_list"),
    fun.aggregate = function(x) (list(x))
    )
  
  
  
  dt_committee_prep[, seasonDisplay := seasonNice(season)]
  dt_committee_prep[, season := NULL]
  
  
  # Column definitions ------------------------------------------------------
  
  
  dt_cols <- data.table(columnID = setdiff(names(dt_committee_prep),"seasonDisplay"))
  dt_cols[, title := columnID]
  
  dt_cols[, columnID := ordered(columnID, c("President", "Vice President", "Secretary","Treasurer","Time Keeper","Other"))]
  setorder(dt_cols, columnID)
  
  # Save --------------------------------------------------------------------
  
  
  path_out <- file.path(path_source, "committee.json")
  
  list_out <- list(tab = list(data = dt_committee_prep,
                              colDefs = dt_cols))
  
  write_json(list_out, path_out)
  
  

}