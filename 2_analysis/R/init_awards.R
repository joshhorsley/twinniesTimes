init_awards <- function(conn, path_manual) {
  
  dt_awards_wide <- read_excel(path_manual,sheet = "awards") |> 
    as.data.table()
  
  
  dt_awards <- melt.data.table(dt_awards_wide,
                                  id.vars = "season",
                                  variable.name = "award",
                                  value.name = "id_member")
  
  
  dt_awards <- dt_awards[!(is.na(id_member) | id_member=="VACANT"), .(id_member = trimws(unlist(strsplit(id_member,";")))), by = .(season, award)]
  
  
  dbAppendTable(conn, "awards", dt_awards)
  
  
}

if(FALSE) {
  
  dt_awards[!(id_member %in% dbReadTable(conn, "members")$id_member)]
  
}