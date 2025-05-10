
export_printListTeams <- function(
    dt_start_print,
    date_ymd_nice,
    dt_marshals,
    milestones = c(25,50),
    milestones_season = 5,
    race_names_display = list(races_all = "All",
                              races_full = "Sprint+"),
    distancseSprintPlus = c("Sprint","Double Sprint")
) {
  
  
  # Expected milestones -----------------------------------------------------
  
  
  ## ever
  dt_start_print[, racesMetricUse := ifelse(races_all > 2*races_full, "races_all", "races_full")]
  dt_start_print[!is.na(racesMetricUse), racesUse := mget(racesMetricUse), by = Name]
  dt_start_print[, racesIncrement := as.integer(racesMetricUse=="races_full" & Distance %in% distancseSprintPlus | racesMetricUse=="races_all")]
  dt_start_print[, racesExpected := racesUse + racesIncrement]
  
  dt_start_print[, isMilestoneEver := racesIncrement==1 & racesExpected %in% milestones | racesExpected %% milestones[length(milestones)] == 0]
  
  
  if(any(dt_start_print$isMilestoneEver)) {
    
    dt_start_print[(isMilestoneEver),
                   notableDisplayEver := glue("{count} {type}",
                                              count = racesExpected,
                                              type = race_names_display[[racesMetricUse]]
                   ), by = Name]
  } else {
    dt_start_print[, notableDisplayEver := NA]
  }
  # dt_start_print[!(isMilestoneEver), notableDisplayEver := ""]
  
  
  ## this season
  dt_start_print[, racesExpectedSeason := races_all_this_season + 1L]
  dt_start_print[, isMilestoneSeason := racesExpectedSeason %in% milestones_season]
  
  if(any(dt_start_print$isMilestoneSeason)) {
    
  dt_start_print[(isMilestoneSeason), notableDisplaySeason := glue("{count} season",
                                                                   count = racesExpectedSeason),
                 by = Name]
  } else {
    dt_start_print[, notableDisplaySeason := NA]
  }
  # dt_start_print[!(isMilestoneSeason), notableDisplaySeason := ""]
  
  # dt_start_print[, notableList := list(list(notableDisplayEver = notableDisplayEver, notableDisplaySeason = notableDisplaySeason)), by = Name]
  
  
  dt_start_print[, notableDisplay := pasteDropNA(c(notableDisplayEver, notableDisplaySeason)), by = Name]
  
  
  
  
  
  
  # prep --------------------------------------------------------------------
  
  
  dt_use_reg <- dt_start_print[order(as.numeric(Bib)), .(Bib, Name, Distance,
                                                         # `Start` = wave_time,
                                                         `Expected\nMilestone` = notableDisplay)]
  
  
  # workbook
  wb <- createWorkbook()
  
  
  ## Registration ------------------------------------------------
  
  
  sheet_reg <- "Registrations"
  addWorksheet(wb, sheet_reg)
  
  
  ## Summary stats -----------------------------------------------------------
  
  
  dt_summary_stats <- groupingsets(dt_use_reg,
                                   j = list(N = .N),
                                   by = c("Distance"),
                                   sets = list("Distance",character()),
                                   id = TRUE)[1]
  
  # dt_summary_stats[grouping==1, Distance := "All"]
  dt_summary_stats[, grouping := NULL]
  # setorder(dt_summary_stats, -N)
  
  
  # Write -------------------------------------------------------------------
  
  
  
  # title
  title_reg <- glue::glue("Registrations {date}",
                          date = date_ymd_nice) |> 
    as.character()
  
  writeData(wb,sheet_reg,
            x = title_reg,
            startCol = 1,startRow = 1)
  
  addStyle(wb,sheet_reg,createStyle(textDecoration = "bold"),1,1)
  addStyle(wb, sheet_reg, createStyle(wrapText = TRUE),2,4)
  addStyle(wb, sheet_reg, createStyle(wrapText = TRUE),2,5)
  
  # main tables
  writeData(wb,sheet_reg,
            x =dt_use_reg,
            borders = "all",
            startCol = 1,startRow = 2)
  addStyle(wb, sheet_reg,
           style = createStyle(wrapText = TRUE),
           rows = 2:(2+nrow(dt_use_reg)),
           cols = 1:ncol(dt_use_reg),
           gridExpand = TRUE,
           stack = TRUE
  )
  
  
  # summary tables
  writeData(wb,sheet_reg,
            x = dt_summary_stats,
            borders = "all",
            startCol = ncol(dt_use_reg) + 2, startRow = 2)
  
  # marshalls
  if(nrow(dt_marshals)) {
    writeData(wb, sheet_reg,
              x = dt_marshals[, .(Marshals = name_display)],
              borders = "none",
              headerStyle = createStyle(textDecoration = "underline"),
              startCol = ncol(dt_use_reg) + 2, startRow = 2 + nrow(dt_summary_stats) + 2
    )
    
  }

  # page setup
  setColWidths(wb,sheet_reg,
               cols = 1:7,
               widths = c(5, rep("auto",2),12,3, rep("auto",2))
  )
  page_margin <- 0.25
  head_foot_margin <- 0
  pageSetup(wb,sheet_reg,
            left = page_margin,right = page_margin,top = page_margin,bottom = page_margin,
            header = head_foot_margin,footer = head_foot_margin,
            fitToHeight = TRUE, fitToWidth = TRUE)
  
  
  ## Sprint Start Times  ------------------------------------------------
  
  
  # sheet_start <- "Sprint Start"
  # addWorksheet(wb, sheet_start)
  # 
  # # title
  # title_times <- glue::glue("Sprint Start Times {date}",
  #                           date = date_ymd_nice) |> 
  #   as.character()
  # 
  # writeData(wb,sheet_start,
  #           x = title_times,
  #           startCol = 1,startRow = 1)
  # 
  # addStyle(wb,sheet_start,createStyle(textDecoration = "bold"),1,1)
  # 
  # 
  # # data in columns
  # dt_use[, print_col := rep(0:10, each = 50, length.out = .N)]
  # 
  # for(i in unique(dt_use$print_col)) {
  #   
  #   startCol = 1 + 4*i
  #   
  #   writeData(wb,sheet_start,
  #             x = dt_use[print_col == i, -"print_col"],
  #             borders = "all",
  #             startCol = startCol,startRow = 2)
  #   
  #   setColWidths(wb,sheet_start,
  #                cols = startCol:(startCol+4),
  #                widths = c(5, rep("auto",2),3)
  #   )
  # }
  # 
  # 
  # 
  # # page setup
  # page_margin <- 0.25
  # head_foot_margin <- 0
  # pageSetup(wb,sheet_start,
  #           left = page_margin,right = page_margin,top = page_margin,bottom = page_margin,
  #           header = head_foot_margin,footer = head_foot_margin,
  #           fitToHeight = TRUE)
  
  
  ## save  ------------------------------------------------
  # path_out <- file.path(dir_this_week,"2_OUTPUT_start_list","print.xlsx")
  # 
  # saveWorkbook(wb, path_out, overwrite = TRUE)
  
  
  return(wb)
  
  
}
