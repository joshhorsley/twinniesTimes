init_committee <- function(conn, path_manual) {
  
  dt_committee_wide <- read_excel(path_manual,sheet = "committee") |> 
    as.data.table()
  
  
  dt_committee <- melt.data.table(dt_committee_wide,
                                  measure.vars = setdiff(names(dt_committee_wide), c("season","Note")),
                                  id.vars = "season",
                                  variable.name = "role",
                                  value.name = "id_member")
  
  
  dt_committee <- dt_committee[!(is.na(id_member) | id_member=="VACANT"), .(id_member = trimws(unlist(strsplit(id_member,";")))), by = .(season, role)]
  
  
  dbAppendTable(conn, "committee", dt_committee)
  
  
}