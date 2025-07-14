prepJsonAwards <- function(conn, path_source) {
  
  # Load --------------------------------------------------------------------
  
  
  dt_awards <- dt_dbReadTable(conn, "awards")
  dt_members <- dt_dbReadTable(conn, "members")
  
  
# Prep --------------------------------------------------------------------

  
  dt_awards[dt_members, on = .(id_member), name_display := i.name_display]
  
  dt_awards[, row_id := seq(.N)]
  dt_awards[, person_list := list(list(list(name_display = name_display,
                                               id_member = id_member))), by = row_id]
  
  dt_award_prep <- dcast.data.table(
    dt_awards,
    season ~ award,
    # value.var = c("name_display","id_member"),
    value.var = c("person_list"),
    fun.aggregate = function(x) (list(x))
  )
  
  dt_award_prep[, seasonDisplay := seasonNice(season)]
  dt_award_prep[, season := NULL]
  
  
  # Column definitions ------------------------------------------------------
  
  
  dt_cols <- data.table(columnID = setdiff(names(dt_award_prep),"seasonDisplay"))
  dt_cols[, title := columnID]
  
  dt_cols[, columnID := ordered(columnID, c("Presidents Award", "Club Person of the Year", "Encouragement","Galah","Most Couragous Act on 2 wheels","Point Score",
                                            "Overall Male",
                                            "Overall Female",
                                            "Under 18 Male",
                                            "Under 18 Female",
                                            "18-29 Male",
                                            "18-29 Female",
                                            "30-39 Male",
                                            "30-39 Female",
                                            "40-49 Male",
                                            "40-49 Female",
                                            "50-59 Male",
                                            "50-59 Female",
                                            "60-69 Male",
                                            "60-69 Female",
                                            "70+ male",
                                            "70+ Female",
                                            "60+ Male",
                                            "60+ Female",
                                            "18-34 Male",
                                            "18-34 Female",
                                            "35-49 Male",
                                            "35-49 Female",
                                            "50+ Male",
                                            "50+ Female",
                                            "Fastest Swim Overall",
                                            "Fastest Ride Overall",
                                            "Fastest Run Overall",
                                            "Fastest Swim Male",
                                            "Fastest Ride Male",
                                            "Fastest Run Male",
                                            "Fastest Swim Female",
                                            "Fastest Ride Female",
                                            "Fastest Run Female"))]
  setorder(dt_cols, columnID)
  
  
  # Save --------------------------------------------------------------------
  
  
  path_out <- file.path(path_source, "awards.json")
  
  list_out <- list(tab = list(data = dt_award_prep,
                              colDefs = dt_cols))
  
  write_json(list_out, path_out)
}