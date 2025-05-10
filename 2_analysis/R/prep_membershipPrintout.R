
prep_membershipPrintout <- function(conn) {
  
  
# Load --------------------------------------------------------------------

  
  dt_members <- dt_dbReadTable(conn, "members")
  dt_raceResults <- dt_dbReadTable(conn, "raceResults")
  
  dt_twintownMeberships <- dt_dbReadTable(conn, "twintownMemberships")[date_updated==max(date_updated)]
  

# Prep --------------------------------------------------------------------

  
  
  dt_membersRecent <- dt_members[id_member %in% dt_raceResults[season>="2024-2025"]$id_member, .(name_display,twintownsMembershipID, name_last)] 
  
  dt_membersRecent <- rbindlist(list(
    dt_membersRecent,
    dt_twintownMeberships[twintownsMembershipID %notin% dt_membersRecent$twintownsMembershipID,
                          .(
                            name_display = as.character(glue({"{nameFirst} {nameLast}"}), 
                                                        nameFirst = nameFirst,
                                                        nameLast = nameLast),
                            twintownsMembershipID,
                            name_last = nameLast
                            )
                          ]
  ))
  
  cols <- c("date_dueMain","date_dueTriathlon", "financial")
  dt_membersRecent[dt_twintownMeberships, on = .(twintownsMembershipID), (cols) := mget(cols)]
  
  # dates
  date_update <- dt_twintownMeberships[1]$date_update |> as.Date()
  date_soon <- as.Date(rollforward(rollforward(date_update)+1))
  
  dt_membersRecent[, dueSoon_main := as.Date(date_dueMain) <= date_soon]
  dt_membersRecent[, dueSoon_triathlon := as.Date(date_dueTriathlon) <= date_soon]
  
  
  #order
  setorder(dt_membersRecent, name_last)


# Export ------------------------------------------------------------------


  
  wb <- createWorkbook()
  sheet <- "Membership"
  addWorksheet(wb, sheet)
  
  
  ## title
  sheetTitle <- glue("Membership as at {date_updateNice}",
                     date_updateNice = toNiceDate(date_update)) |> 
    as.character()
  
  writeData(wb,sheet,
            x = sheetTitle,
            startCol = 1,startRow = 1)
  addStyle(wb,sheet,createStyle(textDecoration = "bold"),1,1)
  

  ## main table
  dt_membersRecentDisplay <- dt_membersRecent[, .(Name = name_display,
                                                  twintownsMembershipID,
                                                  `TwinTowns Due` = date_dueMain,
                                                  `Triathlon Due` = date_dueTriathlon)]
  
  writeData(wb,sheet,
            x =dt_membersRecentDisplay,
            borders = "all",
            startCol = 1,startRow = 2)
  
  
  # style if due soon
  addStyle(wb,sheet,createStyle(textDecoration = "bold"),2+which(dt_membersRecent$dueSoon_main),3, stack = TRUE)
  addStyle(wb,sheet,createStyle(textDecoration = "bold"),2+which(dt_membersRecent$dueSoon_triathlon), 4, stack = TRUE)
  
  
  
  ## page setup
  setColWidths(wb,sheet,
               cols = 1:4,
               widths = rep("auto",4)
  )
  page_margin <- 0.2
  head_foot_margin <- 0
  pageSetup(wb,sheet,
            left = page_margin,right = page_margin,top = page_margin,bottom = page_margin,
            header = head_foot_margin,footer = head_foot_margin,printTitleRows=2,
            fitToWidth = TRUE)
  
  
  ## save
  path_out <- glue("../3_membership/membership_{date_update}.xlsx")
  saveWorkbook(wb,path_out, overwrite = TRUE)
  
  
  
  
  write.xlsx(dt_membersRecent, "~/Desktop/membership_2024-11-12.xlsx")
  
}