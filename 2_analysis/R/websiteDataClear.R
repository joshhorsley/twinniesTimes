  refreshDir <- function(path) {
    if(dir.exists(path)) unlink(path, recursive = TRUE)
    
    dir.create(path, recursive = TRUE)
  }
  
  
clearWebsiteData <- function(pathsWebsiteData) {
  invisible(lapply(pathsWebsiteData, refreshDir))
  
}