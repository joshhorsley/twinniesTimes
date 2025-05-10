

# Load single file --------------------------------------------------------



load_twinTownsMembershipExcel <- function(path_memberships, members_pass) {
  
  wb <- XLConnect::loadWorkbook(path_memberships,password = members_pass)
  sheet <- XLConnect::getActiveSheetName(wb)
  
  dt_twintowmsMembers <- XLConnect::readWorksheet(wb, sheet) |>
    as.data.table()
  
  date_updated <- dt_twintowmsMembers[grepl("^Triathlon Club Listing", Col1)]$Col1 |> 
    gsub(pattern = "^Triathlon Club Listing (*)", replacement = "\\1") |> 
    dmy() |> 
    as.Date() |> 
    format("%Y-%m-%d")
  
  dt_twintowmsMembers <- dt_twintowmsMembers[!(grepl("^Tri",Col1) | is.na(Col1) | is.na(Col2))]
  
  setnames(dt_twintowmsMembers,
           names(dt_twintowmsMembers),
           c("twintownsMembershipID",
             "nameTitle",
             "nameFirst",
             "nameLast",
             "phoneMobile",
             "phoneOther",
             "email",
             "date_dueMain",
             "date_dueTriathlon",
             "financial")
  )
  
  dt_twintowmsMembers[, `:=`(
    date_dueMain = format(as.Date(date_dueMain),"%Y-%m-%d"),
    date_dueTriathlon = format(as.Date(date_dueTriathlon),"%Y-%m-%d"),
    twintownsMembershipID = as.integer(twintownsMembershipID),
    phoneMobile = as.integer(phoneMobile))]
  
  dt_twintowmsMembers[, date_updated := date_updated]
  
  
}


# Load all ----------------------------------------------------------------


init_twinTownsMembers <- function(conn, path_dir_twintownMemberships, members_pass) {
  
  
  if(missing(members_pass)) stop("Must provide password for spreadsheet")
  
  
  # Locate membership file --------------------------------------------------
  
  
  dt_membershipFiles <- data.table(
    path = list.files(path_dir_twintownMemberships,
                      pattern = "^[^~]*.xlsx$",
                      recursive = TRUE,
                      full.names = TRUE)
  )
  
  
  # Load --------------------------------------------------------------------
  
  
  dt_membershipFiles[, dt_membershipLoad := list(list(load_twinTownsMembershipExcel(path, members_pass))), by = path]
  
  dt_twintowmsMembers <- rbindlist(dt_membershipFiles$dt_membershipLoad)
  
  
  # check have all member IDs
  dt_members <- dt_dbReadTable(conn, "members")
  
  dt_unknown <- dt_twintowmsMembers[twintownsMembershipID %notin% dt_members$twintownsMembershipID]
  
  if(nrow(dt_unknown)) {
    print(dt_unknown)
    stop("Unknown membership IDs found")
  }
  
  
  # Save --------------------------------------------------------------------
  
  
  dbAppendTable(conn, "twintownMemberships",
                dt_twintowmsMembers)
  
  
}
