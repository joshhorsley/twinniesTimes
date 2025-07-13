prepJson_startTimesAll <- function(conn, path_source) {
  
  
  # Load --------------------------------------------------------------------
  
  
  dt_members <-  dt_dbReadTable(conn, "members")
  dt_StartPointsBest <-  dt_dbReadTable(conn, "timesBestPoints")
  dt_memberChipLatest <- dt_dbReadTable(conn, "memberChipLatest")
  dt_racesSeason <- dt_dbReadTable(conn, "races")[season>="2024-2025"]
  dt_raceResults <- dt_dbReadTable(conn, "raceResults")[season >= "2024-2025"]
  
  dt_StartPointsBest[, racedSprint := as.logical(racedSprint) ]
  
  
  # Prep --------------------------------------------------------------------
  
  
  date_min <- min(dt_raceResults$date_ymd)
  
  dt_StartPointsBest[dt_members, on = .(id_member), name_display := i.name_display]
  
  dt_StartPointsBest[, nextStartTime_display := startTimeFromBestTime(nextStartUse)]
  
  dt_StartPointsBest[, dateNextStartDisplay := format(as.Date(date_ymd_next), "%e %b %Y") |> trimws()]
  
  dt_StartPointsBest[, hasChanges := length(unique(nextStartUse[!is.na(nextStartUse)]))>1, by = .(id_member)]
  dt_StartPointsBest[is.na(hasChanges), hasChanges := FALSE]
  
  dt_StartPointsBest[!is.na(nextStartUse), rowHasChange := nextStartUse != shift(nextStartUse, 1), by = (id_member)]
  dt_StartPointsBest[is.na(rowHasChange), rowHasChange := FALSE]
  
  dt_StartPointsBest[(hasChanges), rowInHistory := date_ymd==date_min & is.finite(timeBestPreviousUse) | rowHasChange]
  dt_StartPointsBest[, displayHistory := sum(rowInHistory) > 1, by = .(id_member)]
  
  dt_StartPointsBest[, nextStartTime_displayStatus := ifelse(rowHasChange, "New","")]
  
  dt_StartPointsBest[, hasAnyTimedResults := any(is.finite(timeBestPreviousUse) | is.finite(TimeTotal) )]
  
  dt_out <- dt_StartPointsBest[(hasAnyTimedResults)
                               ,.(nextStartTime_display = nextStartTime_display[.N],
                                  nextStartTime_displayStatus = nextStartTime_displayStatus[.N],
                                  displayHistory = displayHistory[.N],
                                  changeHistory = list(list(
                                    data.table(
                                      date_ymd_next = date_ymd_next[rowInHistory],
                                      dateNextStartDisplay = dateNextStartDisplay[rowInHistory],
                                      nextStartTime_display = nextStartTime_display[rowInHistory])
                                  ))
                               ),
                               by = .(id_member, name_display, hasChanges)]
  dt_out[dt_memberChipLatest, on = .(id_member), chipLatest := i.chip]
  
  dt_out[, hasChangeDisplay := ifelse(displayHistory,"1","")]
  
  
  # Export ------------------------------------------------------------------
  
  
  list_export <- list(dateNext = dt_StartPointsBest[.N, dateNextStartDisplay],
                      tableStarts = dt_out[!is.na(chipLatest)] )
  
  list_export |>
    toJSON(null="null") |> 
    write(file.path(path_source, "startTimes.json"))
  
  # column names
  dt_cols <- data.table(columnID = c("chipLatest","nextStartTime_display","nextStartTime_displayStatus"),
                        title = c("Chip","Start Time", "New")
  )
  
  dt_col_notes <- list(
    nextStartTime_displayStatus =  "New if there are no previous results from this start time during the season"
  ) |>
    list_to_dt()
  
  dt_cols[dt_col_notes, on = .(columnID = name), note := i.value]
  
  dt_cols[columnID != "name_display"] |> 
    jsonlite::toJSON() |> 
    write(file.path(path_source, "startTimes_columns.json"))
  
  
}