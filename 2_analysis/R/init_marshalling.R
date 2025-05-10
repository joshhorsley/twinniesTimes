init_marshalling <- function(conn, path_manual) {
  
  
  dt_marshalling <- read_excel(path_manual, sheet = "marshalling") |> 
    as.data.table()
  
  dt_marshalling[, date_ymd := as.Date(date_ymd)]


  # Save --------------------------------------------------------------------
  
  
  dt_out <- dt_marshalling[, .(date_ymd = format(date_ymd, "%Y-%m-%d"),
                               id_member = id_member)]
  
  dbAppendTable(conn, "marshalling", dt_out)
  
  
}