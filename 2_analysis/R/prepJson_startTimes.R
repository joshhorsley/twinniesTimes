startTimeFromBestTime <- function(x, seconds_finish = 27000) {
  
  out <- character(length(x))
  
  ind_is_finite <- is.finite(x)
  
  out[ind_is_finite] <-  seconds_to_hms_simple(seconds_finish - x[ind_is_finite])
  out[x>5400] <-   "6:00:00"
  # out[!ind_is_finite] <-   NA # this was here for a reason but can't remember
  
  out
}


prepJson_startTimes <- function(conn, path_source,
                                eventStartTimeExclude = "Teams") {
  

# Load --------------------------------------------------------------------

  
  dt_members <-  dt_dbReadTable(conn, "members")
  dt_StartPointsBest <-  dt_dbReadTable(conn, "timesBestPoints")
  dt_memberChipLatest <- dt_dbReadTable(conn, "memberChipLatest")
  dt_racesSeason <- dt_dbReadTable(conn, "races")[season=="2024-2025"]
  
  dt_StartPointsBest[, isWeekZero := isWeekZero == 1] # this smells bad...


# Prep --------------------------------------------------------------------

  
  dt_StartPointsBest[dt_members, on = .(id_member), name_display := i.name_display]
  
  
  # dt_StartPointsBest[, thisStartTime_display := startTimeFromBestTime(timeBestPrevious)]
  dt_StartPointsBest[, nextStartTime_display := startTimeFromBestTime(timeBest)]
  
  
  
  # date next
  dt_racesSeason[special_event %notin% eventStartTimeExclude, dateNext := shift(date_ymd,-1)]
  
  dt_StartPointsBest[dt_racesSeason, on = .(date_ymd), dateNextStart := as.Date(i.dateNext)]
  dt_StartPointsBest[(isWeekZero), dateNextStart := as.Date(dt_racesSeason[1]$date_ymd)]
  # dt_StartPointsBest[, dateNextStart := as.Date(date_ymd) + 7]
  dt_StartPointsBest[, dateNextStartDisplay := format(dateNextStart, "%e %b %Y") |> trimws()]
  
  
  # dt_StartPointsBest[, hasChanges := any(timeDiff < 0), by = .(id_member)]
  # dt_StartPointsBest[!(isWeekZero), hasChanges := any(timeBest < timeBestPrevious), by = .(id_member)]
  dt_StartPointsBest[, hasChanges := any(timeBest < timeBestPrevious & !isWeekZero), by = .(id_member)]
  dt_StartPointsBest[is.na(hasChanges), hasChanges := FALSE]
  
  dt_StartPointsBest[, rowHasChange := hasChanges  & timeBest < timeBestPrevious]
  dt_StartPointsBest[is.na(rowHasChange), rowHasChange := FALSE]
  
  dt_StartPointsBest[(hasChanges), rowInHistory := isWeekZero & is.finite(timeBest) | rowHasChange]
  dt_StartPointsBest[, displayHistory := sum(rowInHistory) > 1, by = .(id_member)]
  
  dt_StartPointsBest[, nextStartTime_displayStatus := ifelse(rowHasChange, "New","")]
  
  dt_StartPointsBest[, hasAnyTimedResults := as.logical(hasAnyTimedResults)]
  

  
  dt_out <- dt_StartPointsBest[(hasAnyTimedResults)
    ,.(nextStartTime_display = nextStartTime_display[.N],
       nextStartTime_displayStatus = nextStartTime_displayStatus[.N],
       displayHistory = displayHistory[.N],
       changeHistory = list(list(
      data.table(dateNextStartDisplay = dateNextStartDisplay[rowInHistory],
                 nextStartTime_display = nextStartTime_display[rowInHistory])
      ))
      ),
    by = .(id_member, name_display, hasChanges)]
  dt_out[dt_memberChipLatest, on = .(id_member), chipLatest := i.chip]
  
  
  # dt_StartPointsBest[id_member=="horsley_josh"]
  # dt_StartPointsBest[id_member=="ravenswood_amanda"]
  # dt_test[id_member=="ravenswood_amanda"]
  # dt_out[id_member=="bartlett_adrian", changeHistory]
  # dt_out[id_member=="bartlett_adrian"]
  # dt_out[id_member=="pearce_clive", changeHistory]
  # dt_out[id_member=="pearce_clive"]
  
  # dt_out[(hasChanges), changeHistory := unlist(changeHistory, recursive = FALSE), by = id_member]
  
  # dt_out[!(hasChanges), changeHistory := NA]
  dt_out[, hasChangeDisplay := ifelse(displayHistory,"1","")]
  

# Export ------------------------------------------------------------------

  
  list_export <- list(dateNext = dt_StartPointsBest[.N, dateNextStartDisplay],
                      # tableStarts = dt_test[id_member %in% c("bartlett_adrian","pearce_clive")] )
                      tableStarts = dt_out )
  
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

if(FALSE) {
  
  dt_StartPointsBest$date_ymd |> as.Date()
  
  dt_StartPointsBest[id_member=="bartlett_adrian"]
  dt_StartPointsBest[id_member=="pearce_clive"]
  dt_StartPointsBest[id_member=="pearce_clive"]$changeHistory
  dt_StartPointsBest[id_member=="lowth_gavin"]
  dt_StartPointsBest[id_member=="wilkes_ben"]
  dt_StartPointsBest[id_member=="graham_sera"]
  
  
  dt_StartPointsBest[, .(dateNextStartDisplay = dateNextStartDisplay[1],
                         starts = list(data.table(
                           id_member,
                           name_display,
                           nextStartTime_display,
                           changeHistory))),
                     by = dateNextStart][order(dateNextStart)][2,starts][[1]][43,changeHistory ]
  
  
  dt_StartPointsBest[id_member=="temperly_aled"]
  dt_out[id_member=="temperly_aled"]
}