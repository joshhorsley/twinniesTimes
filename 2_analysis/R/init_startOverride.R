init_startOverride <- function(
    conn,
    path_manual
) {
  
  dt_overrides <- read_excel(path_manual, sheet = "startOverride") |> 
    setDT()
  
  dbAppendTable(conn, "startOverride", dt_overrides)
}