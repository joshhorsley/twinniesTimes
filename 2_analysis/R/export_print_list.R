
export_print_list <- function(
    dt_start_print,
    date_ymd_nice,
    dt_marshals,
    milestones = c(25,50),
    milestones_season = 5,
    distancseSprintPlus = c("Sprint","Double Sprint"),
    do_genderCats = FALSE
) {
  
  
  # Expected milestones -----------------------------------------------------
  
  
  ## ever
  dt_start_print[, is_fullDistance := Distance %in% distancseSprintPlus]
  
  dt_start_print[, increment := as.integer(totalRacesMetric=="all" | (totalRacesMetric=="full" & is_fullDistance))]
  
  dt_start_print[!is.na(totalRacesMetric), racesUse := ifelse(totalRacesMetric=="all", races_all, races_full), by = Name]
  dt_start_print[, racesExpected := racesUse + increment]
  
  dt_start_print[, isMilestoneEver := increment==1 & (racesExpected %in% milestones | racesExpected %% milestones[length(milestones)] == 0)]
  dt_start_print[is.na(isMilestoneEver), isMilestoneEver := FALSE]
  
  dt_start_print[, notableDisplayEver := ifelse(isMilestoneEver,
                                                glue("{count} total",
                                                     count = racesExpected),
                                                ""
  ), 
  by = Name]
  
  ## this season
  dt_start_print[, racesExpectedSeason := ifelse(is.na(races_all_this_season), 1L,races_all_this_season + 1L)]
  dt_start_print[, isMilestoneSeason := racesExpectedSeason %in% milestones_season]
  
  dt_start_print[, notableDisplaySeason := ifelse(isMilestoneSeason,
                                                  glue("{count} season", count = racesExpectedSeason),
                                                  ""),
                 by = Name]
  
  dt_start_print[, notableDisplay := pasteDropEmpty(c(notableDisplayEver, notableDisplaySeason)), by = Name]
  
  
  # prep --------------------------------------------------------------------
  
  if(!do_genderCats) {
    
    dt_use_reg <- dt_start_print[order(as.numeric(Bib)), .(Bib, Name, Distance,
                                                           `Start` = wave_time,
                                                           `Expected\nMilestone` = notableDisplay)]
    
  } else {
    
    dt_use_reg <- dt_start_print[order(as.numeric(Bib)), .(Bib, Name, Distance,
                                                           Category, Gender,
                                                           `Start` = wave_time,
                                                           `Expected\nMilestone` = notableDisplay)]
    
  }
  
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
                                   id = TRUE)
  
  dt_summary_stats[grouping==1, Distance := "All"]
  dt_summary_stats[, grouping := NULL]
  setorder(dt_summary_stats, -N)
  
  
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
  cols_width <- if(do_genderCats) {
    c(5, rep("auto",4),12,10,3, rep("auto",2))
    
  } else {
    
    c(5, rep("auto",2),12,10,3, rep("auto",2))
  }
  


setColWidths(wb,sheet_reg,
             cols = seq(length(cols_width)),
             widths = cols_width
)
page_margin <- 0.25
head_foot_margin <- 0
pageSetup(wb,sheet_reg,
          left = page_margin,right = page_margin,top = page_margin,bottom = page_margin,
          header = head_foot_margin,footer = head_foot_margin,
          fitToHeight = TRUE, fitToWidth = TRUE)




return(wb)


}
