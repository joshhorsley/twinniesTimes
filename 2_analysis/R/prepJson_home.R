prepJson_home <- function(path_source) {
  
  
  
  dataHome <- list(dateUpdate = toNiceDate(Sys.Date()))
  
  dataHome |> 
    toJSON() |> 
    write(file.path(path_source, "home.json"))
  
}
