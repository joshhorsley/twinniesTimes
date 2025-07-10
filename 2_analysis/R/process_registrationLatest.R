#' Start time   - character hms after time0 for start - used for webscorer control
#' Wave         - character label for waves in webscorer, not used for control
#' wave_time    - character hms display on print sheet, not used for control


prep_startLatest <- function(conn,
                             messages = TRUE) {
  
  
  # Load --------------------------------------------------------------------
  
  
  # Registrations
  dt_reg <- dt_dbReadTable(conn, "registrations")[date_ymd==max(date_ymd)]
  date_ymd_use <- dt_reg[1]$date_ymd
  
  
  dt_bestTimes <-  dt_dbReadTable(conn, "timesBestPoints")[date_ymd_next==date_ymd_use, .(id_member, nextStartUse)]
  
  if(nrow(dt_bestTimes)==0) stop("Do not have start times available for this date - do previous races need to flagged as cancelled?")
  dt_members <- dt_dbReadTable(conn, "members")
  
  dt_memberChipLatest <- dt_dbReadTable(conn, "memberChipLatest")
  dt_memberChipLatest[, chip_character := as.character(chip)]
  
  dt_raceInfo <- dt_dbReadTable(conn, "races")[date_ymd==date_ymd_use, .(start_time_change, season)]
  
  dt_totalRacesOverall <- dt_dbReadTable(conn, "totalRacesOverall")
  
  dt_totalRacesThisSeason <- dt_dbReadTable(conn, "totalRacesSeason")[season==dt_raceInfo$season]
  
  dt_marshals <- dt_dbReadTable(conn, "marshalling")[date_ymd==date_ymd_use]
  dt_marshals[dt_members, on = .(id_member), name_display := i.name_display]
  
  handicapped_distance <- ifelse("Sprint" %in% dt_reg$Distance, "Sprint", "Palindrome Tri")
  
  
  # Dates -------------------------------------------------------------------
  
  
  date_ymd_nice <- date_ymd_use |> as.Date() |> format("%e %b %Y") |> trimws()
  
  if(messages) message("Preparing start lists for: ", date_ymd_use)
  
  
  # Paths -------------------------------------------------------------------
  
  
  paths_out <- list()  
  
  paths_out$dir_out <- file.path("../3_startLists", date_ymd_use)
  refreshDir(paths_out$dir_out)
  
  paths_out$webscorer <- file.path(paths_out$dir_out,
                                   glue("{date_ymd_nice}.xlsx",
                                        date_ymd_nice = date_ymd_nice))
  
  paths_out$print <- file.path(paths_out$dir_out,"print.xlsx")
  
  
  # start offset ------------------------------------------------------------
  
  
  dt_timeOffsets <- data.table(time0 = hmToSeconds(dt_raceInfo$start_time_change))
  
  dt_timeOffsets[, startOffset := 21600L - time0] 
  
  
  # Always included options -------------------------------------------------
  
  
  dt_always_options <- list("Placeholder Aquabike 6:15" = 15*60,
                            "Placeholder Tempta 6:15" = 15*60,
                            "Placeholder Swimrun 6:15" = 15*60,
                            "Placeholder Sprint Non-handicapped 6:00" = 0) |> 
    list_to_dt()
  
  setnames(dt_always_options, c("name","value"), c("Name","seconds_offset"))
  
  dt_always_options[, `Start time` := seconds_to_hms_simple(dt_timeOffsets$startOffset + seconds_offset)]
  dt_always_options[, Wave := seconds_to_hms_simple(21600L + seconds_offset)]
  dt_always_options[, Distance := c("Aquabike","Tempta","Swimrun","Sprint")]
  dt_always_options[, Category := c("All","All","All","Non-handicapped")]
  
  
  dt_always_options[, Bib := NA]  
  
  
  # add 5:30 option if double distance
  if(dt_timeOffsets$time0==18900) {
    dt_always_options <- rbindlist(
      list(
        dt_always_options,
        data.table(Name = "Placeholder 5:30",
                   seconds_offset = 900,
                   `Start time` = "0:15:00",
                   Wave = "5:30:00",
                   Distance = "Double Sprint",
                   Category = "All",
                   Bib = NA)
      )
    )
  }
  
  
  # Process -----------------------------------------------------------------
  
  
  # join
  dt_bestTimes[dt_memberChipLatest, on = .(id_member), chip_character := as.character(i.chip)]
  dt_bestTimes[dt_members, on = .(id_member), name_display := i.name_display]
  dt_bestTimes[dt_reg, on = .(chip_character = Bib),  name_registration := i.Name]
  
  
  # prep wave times
  dt_bestTimes[, `Start time`:= seconds_to_hms_simple(dt_timeOffsets$startOffset + 5400 - min(nextStartUse, 5400)), by = .(id_member)]
  dt_bestTimes[, wave_time := seconds_to_hms_simple(7.5*3600 - min(nextStartUse, 5400)), by = .(id_member)]
  dt_bestTimes[, wave_names := paste0(name_display, collapse = ", "), by = .(`Start time`) ]
  
  dt_bestTimes[wave_time != "6:15:00", Wave :=  as.character(glue::glue_data(.SD, "{wave_time} ({wave_names})"))]
  dt_bestTimes[wave_time == "6:15:00", Wave :=  wave_time]
  
  switch(handicapped_distance,
         Sprint = {
           dt_bestTimes[, Distance := "Sprint"]
           dt_bestTimes[, Category := "Handicap Points"]
           
         },
         "Palindrome Tri" = {
           dt_bestTimes[, Distance := "Palindrome Tri"]
           dt_bestTimes[, Category := "All"]
           
         })
  
  
  
  # non-sprint distances - this takes bib from registration
  distances_615 <- c("Tempta", "Swimrun","Aquabike", "Palindrome Aquabike")
  
  dt_reg_non_sprint1 <- dt_reg[Distance %in% distances_615,
                               .(Name, Distance, 
                                 Category  = "All",
                                 Bib,
                                 Wave = "6:15:00",
                                 wave_time = "6:15:00",
                                 `Start time` = seconds_to_hms_simple(dt_timeOffsets$startOffset + 900))]
  
  # Double Distancse
  dt_reg_non_sprint2 <- dt_reg[Distance %in% c("Double Sprint"), .(Name, Distance, 
                                                                   Category  = "All",
                                                                   Bib,
                                                                   Wave = "5:15:00",
                                                                   wave_time = "5:15:00",
                                                                   `Start time` = seconds_to_hms_simple(0))]
  
  dt_reg_non_sprint3 <- dt_reg[Distance %in% c("Double Aquabike"), .(Name, Distance, 
                                                                     Category  = "All",
                                                                     Bib,
                                                                     Wave = "5:30:00",
                                                                     wave_time = "5:30:00",
                                                                     `Start time` = seconds_to_hms_simple(900))]
  
  dt_reg_non_sprint <- rbindlist(
    list(
      dt_reg_non_sprint1,
      dt_reg_non_sprint2,
      dt_reg_non_sprint3)
  )
  
  
  # new sprint people - this takes bib from registration
  distances_handicapped <- c("Sprint", "Palindrome Tri")
  
  dt_sprint_new <- dt_reg[Bib %notin% dt_bestTimes$chip & Distance %in% distances_handicapped,
                          .(Name,
                            Distance,
                            Category = "Non-handicapped",
                            Bib,
                            Wave = "6:00:00",
                            wave_time = "6:00:00",
                            `Start time` = seconds_to_hms_simple(dt_timeOffsets$startOffset))]
  
  
  # sprint times for those with a time but doing other distances
  dt_sprint_placeholders <- dt_bestTimes[chip_character %in% dt_reg_non_sprint$Bib,
                                         .(Name = as.character(glue::glue("Placeholder Sprint {name} {chip}",
                                                                          name = name_registration,
                                                                          chip = chip_character)), 
                                           Distance = "Sprint",
                                           Category = "Handicap Points",
                                           Bib = NA,
                                           Wave,
                                           `Start time`)]
  
  
  dt_all_with_time_except_non_sprint <- dt_bestTimes[chip_character %notin% dt_reg_non_sprint$Bib,
                                                     .(Name = name_display,
                                                       Distance,
                                                       Category,
                                                       Bib = chip_character,
                                                       Wave,
                                                       `Start time`)]
  
  dt_all_registered_except_non_sprint <- dt_bestTimes[chip_character %in% dt_reg$Bib & chip_character %notin% dt_reg_non_sprint$Bib,
                                                      .(Name = name_display,
                                                        Distance,
                                                        Category,
                                                        Bib = chip_character,
                                                        Wave,
                                                        wave_time,
                                                        `Start time`)]
  
  
  # Export webscorer --------------------------------------------------------
  
  
  # webscorer
  dt_start_webscorer_out <- rbindlist(
    list(
      dt_reg_non_sprint[, .(Name, Distance, Category, Bib, Wave, `Start time`)],
      dt_sprint_new[, .(Name, Distance, Category, Bib, Wave, `Start time`)],
      dt_sprint_placeholders[, .(Name, Distance, Category, Bib, Wave, `Start time`)],
      dt_all_with_time_except_non_sprint[, .(Name, Distance, Category, Bib, Wave, `Start time`)],
      dt_always_options[, .(Name, Distance, Category, Bib, Wave, `Start time`)]
    )
  )
  
  setorder(dt_start_webscorer_out,`Start time`)
  
  
  write.xlsx(dt_start_webscorer_out, paths_out$webscorer)
  
  
  
  # Export print ------------------------------------------------------------
  
  
  dt_start_print <- rbindlist(
    list(
      dt_reg_non_sprint[, .(Name, Distance, Category, Bib, wave_time)],
      dt_sprint_new[, .(Name, Distance, Category, Bib, wave_time)],
      dt_all_registered_except_non_sprint[, .(Name, Distance, Category, Bib, wave_time)]
    )
  )
  
  dt_start_print[dt_memberChipLatest, on = .(Bib = chip_character), id_member := i.id_member]
  dt_start_print[dt_totalRacesOverall, on = .(id_member), `:=`(races_full = i.races_full,
                                                               races_all = i.races_all)]
  
  dt_start_print[dt_members, on = .(id_member), totalRacesMetric := i.totalRacesMetric]
  
  dt_start_print[dt_totalRacesThisSeason, on = .(id_member), `:=`(races_all_this_season = i.races_all)]
  
  
  wb <- export_print_list(dt_start_print, date_ymd_nice, dt_marshals = dt_marshals)
  
  saveWorkbook(wb, paths_out$print, overwrite = TRUE)
  
  
  # Checks ------------------------------------------------------------------
  
  
  if(messages) {
    dt_concern <- dt_reg[acknowledge_timing!="Y" | acknowledge_roadRules!="Y"]  
    
    if(nrow(dt_concern)) {
      
      message("Acknowledgement issues:")
      print(dt_reg[acknowledge_timing!="Y" | acknowledge_roadRules!="Y"])
    }
  }
  
  
}