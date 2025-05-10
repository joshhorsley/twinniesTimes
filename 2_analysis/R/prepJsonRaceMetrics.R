
prepJsonClubMetrics <- function(conn, path_source) {
  
  
  # Load --------------------------------------------------------------------
  
  
  dt_registrations <- dt_dbReadTable(conn, "registrations")
  dt_races <- dt_dbReadTable(conn, "races")
  dt_raceResults <- dt_dbReadTable(conn, "raceResults")
  
  
  date_now <- Sys.Date() |> format("%Y-%m-%d")
  
  # Numbers per race plot  -----------------------------------------------------------------
  
  
  dt_countsReg <- dt_registrations[, .(registrations = .N), by = date_ymd]
  dt_countsFinishers <- dt_raceResults[date_ymd %in% unique(c(dt_registrations$date_ymd),dt_raceResults),
                                       .(finishers = .N), by = .(date_ymd)]
  
  dt_raceStats <- dt_races[season >= "2023-2024" & date_ymd <= max(dt_raceResults$date_ymd, dt_registrations$date_ymd),
                           .(date_ymd, season, special_event, external, cancelled_reason)]
  
  dt_raceStats[, isPast := date_ymd <= date_now]
  
  dt_raceStats[, raceNumber := seq(.N), by = season]
  
  dt_raceStats[dt_countsReg, on = .(date_ymd), registrations := i.registrations]
  dt_raceStats[dt_countsFinishers, on = .(date_ymd), finishers := i.finishers]
  
  dt_raceStats[, finishToRegRatio := finishers/registrations]
  
  dt_raceStats[, colorSeason := ifelse(season==max(season), "blue","grey")]
  dt_raceStats[, widthSeason := ifelse(season==max(season), "2","1")]
  
  dt_raceStats[, eventLetter := substr(special_event,1,1)]
  dt_raceStats[, externalLetter := substr(external,1,1)]
  dt_raceStats[, letterDisplay := pasteDropNA(c(eventLetter, externalLetter), collapse = "+"), by = date_ymd]
  
  dt_raceStats[, seasonDisplay :=  seasonNice(season)]
  dt_raceStats[, dateDisplay := toNiceDate(date_ymd)]
  
  dt_raceStats[, finishersDisplay := ifelse(is.na(finishers), "no results", finishers)]
  
  dt_raceStats[, specialEventDisplay := ifelse(is.na(special_event),"",special_event)]
  dt_raceStats[, externalEventDisplay := ifelse(is.na(external),"",external)]
  
  dt_raceStats[, eventDisplay := pasteDropNA(c(special_event, external),collapse = " + "), by = date_ymd]
  
  dt_raceStats[, ratioDisplay := ifelse(is.na(finishers),"no results",format(round(finishers/registrations,2),digits=2))]
  
  dt_raceStats[, haveRego := !is.na(registrations)]
  dt_raceStats[, haveResults := !is.na(finishers)]
  
  
  ## data
  dt_data <- dt_raceStats[, data.table(
    list(
      list(
        name = paste0("Registrations ", seasonDisplay[1]),
        x = raceNumber,
        y = registrations,
        mode = "lines",
        # type = "scatter",
        line = list(
          dash = "dot",
          color = colorSeason[1],
          width = widthSeason[1]
        ),
        
        customdata = data.table(
          seasonDisplay = seasonDisplay,
          raceNumber = raceNumber,
          dateDisplay = dateDisplay,
          eventDisplay = eventDisplay,
          registrations = registrations,
          finishersDisplay = finishersDisplay,
          ratioDisplay = ratioDisplay
          
          
        ),
        hovertemplate = 
          "<b>%{customdata.dateDisplay}</b><br>Race %{customdata.raceNumber} of %{customdata.seasonDisplay}<br>%{customdata.eventDisplay}<br>Registrations: %{customdata.registrations}<br>Finishers: %{customdata.finishersDisplay}<br><br>Ratio: %{customdata.ratioDisplay}<extra></extra>"
        
      ),
      list(
        name = paste0("Finishers ", seasonDisplay[1]),
        mode = "lines+markers+text",
        # type = "scatter",
        # mode = "lines+text",
        x = raceNumber,
        y = finishers,
        # text = eventLetter,
        text = letterDisplay,
        textposition = "top center",
        textfont = list(
          color = colorSeason[1]
        ),
        line = list(
          color = colorSeason[1],
          width = widthSeason[1]
        ),
        
        customdata = data.table(
          seasonDisplay = seasonDisplay,
          raceNumber = raceNumber,
          dateDisplay = dateDisplay,
          eventDisplay = eventDisplay,
          registrations = registrations,
          finishersDisplay = finishersDisplay,
          ratioDisplay = ratioDisplay
          
          
        ),
        hovertemplate = 
          "<b>%{customdata.dateDisplay}</b><br>Race %{customdata.raceNumber} of %{customdata.seasonDisplay}<br>%{customdata.eventDisplay}<br>Registrations: %{customdata.registrations}<br>Finishers: %{customdata.finishersDisplay}<br><br>Ratio: %{customdata.ratioDisplay}<extra></extra>"
        
      )
    )
  ), by = season]
  
  
  ## axes
  y_max <- max(dt_raceStats$finishers, dt_raceStats$registrations, na.rm = TRUE)
  yaxisAddIn <- list(
    title = "People",
    range = c(0,y_max * 1.05))
  
  xaxisAddIn <- list(
    title = "Week in season",
    range = c(0,max(dt_raceStats$raceNumber)+1)
  )
  
  setorder(dt_data, -season)
  
  
  
  ## letter definitions
  
  dt_letters <- melt.data.table(dt_raceStats,
                                id.vars = "date_ymd",
                                measure.vars = list(c("eventLetter","externalLetter"),
                                                    c("special_event","external")),
                                # variable.name = c("internal","external"),
                                value.name = c("letter","text"))[, .(text = unique(text)), by = letter][order(letter)][letter!=""]
  
  
  
  # Numbers per race summary ------------------------------------------------
  
  
  weeksPassed <- dt_raceStats[season==max(season) & (isPast), max(raceNumber)] 
  
  dt_raceStats[, isPastWeek := raceNumber <= weeksPassed]
  dt_raceStats[, seasonRelative := ifelse(season==max(season), "current", "previous")]
  
  dt_summaryCompare <- list(
    soFar = dt_raceStats[(isPastWeek),
                         lapply(.SD, function(x) round(mean(x,na.rm = TRUE),1)),
                         .SDcols = c("registrations","finishers"),
                         by = seasonRelative ],
    
    allWeeks =  dt_raceStats[,
                             lapply(.SD, function(x) round(mean(x,na.rm = TRUE),1)),
                             .SDcols = c("registrations","finishers"),
                             by = seasonRelative ]
    
  ) |> 
    rbindlist(id = "period") |> 
    melt.data.table() |> 
    dcast.data.table(variable + period ~ seasonRelative, value.var = "value")
  
  dt_summaryCompare[, change := current - previous]
  
  
  dt_summaryComparePrep <- dt_summaryCompare[, .(valuesList = list(list(list(previous = previous,
                                                                             current = current,
                                                                             change = change)))), by = .(period, variable)]
  
  l2 <- split(dt_summaryCompare, by = c("period", "variable"), flatten = FALSE, keep.by = FALSE)
  
  
  
  
  # Newcomers ---------------------------------------------------------------
  
  
  dt_newcomersByDate <- dt_dbReadTable(conn, "totalRacesDate")[season >= "2023-2024" & races_all ==1, .(newcomers = .N), by = .(season, date_ymd)][order(date_ymd)]
  
  
  
  
  # Save --------------------------------------------------------------------
  
  
  list_export <- list(numbersPerRace = list(plotNumbers = list(data = dt_data$V1,
                                                               yaxisAddIn = yaxisAddIn,
                                                               xaxisAddIn = xaxisAddIn),
                                            eventLetters = dt_letters,
                                            summaryNumbers = list(weeksPassed = weeksPassed,
                                                                  summaryCompare = l2)
  ))
  
  list_export |> 
    jsonlite::toJSON(auto_unbox = TRUE, pretty = TRUE) |>
    # remove boxing from legendrank
    # gsub(pattern = "\"legendrank\": \\x5B([0-9])\\x5D", replacement ="\"legendrank\": \\1") |> 
    
    write(file.path(path_source, "clubMetrics.json"))
  
}
