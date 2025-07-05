# for 2024-2025 onwards

create_webscorer_directories <- function(conn, path_webscorer) {
  
  dt_races_recent <- dt_dbReadTable(conn, "races")[season >= "2024-2025", .(season, date_ymd)]
  
  dt_dirs <- CJ(
    date_ymd = dt_races_recent$date_ymd,
    dir_type = c("1_INPUT_registration","3_INPUT_race_results")
  )
  dt_dirs[dt_races_recent, on = .(date_ymd), season := i.season]
  
  dt_dirs[, path_full := file.path(path_webscorer, season, date_ymd, dir_type)]
  
  dt_dirs[, dir_exists := dir.exists(path_full)]
  
  if(any(!dt_dirs$dir_exists)) {
    dt_dirs[!(dir_exists), created_dir := dir.create(path_full, recursive = TRUE), by = path_full]
  }
  
  if(any(dt_dirs$created_dir)) {
    message("Created race registation & result directories")
  }
  
}