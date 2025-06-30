prepJsonPoints <- function(conn, path_source, tri_cols) {
  
  
  # Load --------------------------------------------------------------------
  
  
  dt_members <-  dt_dbReadTable(conn, "members")
  dt_StartPointsBest <-  dt_dbReadTable(conn, "timesBestPoints")
  
  dt_StartPointsBest[, isWeekZero := isWeekZero ==1]
  
  
  # Common ------------------------------------------------------------------
  
  dt_date_max <- dt_StartPointsBest[, .(date_max = max(date_ymd)), by = .(season)]
  
  dt_StartPointsBest[, hasAnyPoints := any(points_all_total!=0), by = .(id_member, season)]
  
  setorder(dt_StartPointsBest, id_member, date_ymd)
  
  dt_StartPointsBest[, hasPointsChange := points_all_awarded!=0]
  
  dt_StartPointsBest[dt_members, on = .(id_member), name_display := i.name_display]
  
  
  # Plot --------------------------------------------------------------------
  
  
  dt_pointsPlot <- copy(dt_StartPointsBest)
  
  dt_pointsPlot[(hasAnyPoints), y_plot := frank(points_all_total,ties.method = "first"), by = .(date_ymd, season)]
  
  
  dt_pointsPlot[, rankIsEqual := .N>1, by = .(date_ymd, season, rank_all_total)]
  
  dt_pointsPlot[, placeDisplay := as.character(
    glue("{rankDisplay}{optionalEqual}",
         rankDisplay = ordinal_suffix_of(rank_all_total),
         optionalEqual = ifelse(rankIsEqual, " (eq)", "")
    )
  )]
  
  
  ## data --------------------------------------------------------------------
  
  
  dt_pointsPlotData <- dt_pointsPlot[!(isWeekZero) & (hasAnyPoints), data.table(
    frames = list(list(
      name = toNiceDateShort(date_ymd),
      data = list(
        list(
          name = "Participation",
          legendrank= "2",
          base = rep(0, .N),
          x = points_particiation_total,
          y = y_plot,
          marker = list(color = tri_cols$club_1),
          
          customdata = data.table(
            name_display = name_display,
            points_particiation_total = points_particiation_total,
            points_participation_awarded = points_participation_awarded,
            points_all_total = points_all_total,
            points_all_awarded = points_all_awarded,
            placeDisplay = placeDisplay
          ),
          hovertemplate = "<b>%{customdata.name_display}</b><br>
          Place: %{customdata.placeDisplay}<br>
          Total: %{customdata.points_all_total}<br>
          This race: %{customdata.points_all_awarded}<br><br>
          Participation Points<br>
          Subtotal: %{customdata.points_particiation_total}<br>
          This race: %{customdata.points_participation_awarded}
          <extra></extra>"
        ),
        list(
          name = "Handicap",
          legendrank= "1",
          base = points_particiation_total,
          x = points_handicap_total,
          y = y_plot,
          text = name_display,
          constraintext= "none",
          textposition= "outside",
          textangle= "0",
          textfont = list(size = 20),
          marker = list(color = tri_cols$club_3),
          
          customdata = data.table(
            name_display = name_display,
            points_handicap_total = points_handicap_total,
            points_handicap_awarded = points_handicap_awarded,
            points_all_total = points_all_total,
            points_all_awarded = points_all_awarded,
            placeDisplay = placeDisplay
            
          ),
          hovertemplate = "<b>%{customdata.name_display}</b><br>
          Place: %{customdata.placeDisplay}<br>
          Total: %{customdata.points_all_total}<br>
          This race: %{customdata.points_all_awarded}<br><br>
          Handicap Points<br>
          Subtotal: %{customdata.points_handicap_total}<br>
          This race: %{customdata.points_handicap_awarded}
          <extra></extra>"
        ))
    ))
  ), by = .(date_ymd, season)]
  
  
  ## annotation --------------------------------------------------------------------
  
  
  #' for appropriate range
  dt_pointsPlot[, is_max_points_season := points_all_total == max(points_all_total), by = .(season)]
  dt_pointsPlot[(is_max_points_season), max_ref := seq(.N), by = season]
  
  dt_plotRefs <- dt_pointsPlot[(is_max_points_season) & max_ref==1]
  
  dt_plotRefs[, plotAnnotation :=  data.table(list(
    list(
      x = points_all_total*1.02,
      y = y_plot + 5.01,
      xanchor = "left",
      font = list(size = 20),
      text = name_display
      
    )
  )), by = season]
  
  
  ## yaxis --------------------------------------------------------------------
  
  
  dt_n_athletes <- dt_pointsPlot[(hasAnyPoints), .(n_athletes = max(y_plot, na.rm = TRUE)), by = season]
  
  dt_plotRefs[dt_n_athletes, on = .(season), n_athletes := i.n_athletes]
  dt_plotRefs[, yTickList := list(list(c(1,seq(from = 5, to = n_athletes, by = 5))))]
  
  dt_plotRefs[, yaxisAddIn := data.table(list(list(
    tickmode = "array",
    range = c(0, dt_maxPoints$y_plot + 1),
    tickvals = n_athletes - unlist(yTickList) + 1,
    ticktext = unlist(yTickList)
    
  ))), by = season ]
  
  
  # Table -------------------------------------------------------------------
  
  
  dt_pointsTab <- dt_StartPointsBest[(hasAnyPoints),
                                     .(date_ymd = date_ymd[.N],
                                       name_display = name_display[.N],
                                       rank_all_total = rank_all_total[.N],
                                       points_all_total = points_all_total[.N],
                                       points_particiation_total = points_particiation_total[.N],
                                       points_handicap_total  = points_handicap_total[.N],
                                       pointsHistory = list(list(
                                         data.table(
                                           date_ymd = date_ymd[hasPointsChange],
                                           dateDisplay = toNiceDate(date_ymd[hasPointsChange]),
                                           points_participation_awarded = points_participation_awarded[hasPointsChange],
                                           points_handicap_awarded = points_handicap_awarded[hasPointsChange],
                                           points_all_total = points_all_total[hasPointsChange]
                                           
                                         )
                                       ))),
                                     by = .(id_member, season)]
  
  
  dt_pointsTab[, rankIsEqual := .N>1, by = .(rank_all_total, season)]
  
  dt_pointsTab[, hasChangeDisplay := "1"]
  
  
  # Column definitions ------------------------------------------------------
  
  
  dt_cols <- data.table(columnID = c("points_all_total","points_particiation_total","points_handicap_total"),
                        title = c("Total","Participation","Handicap"))
  
  
  # Save --------------------------------------------------------------------
  
  
  for( i_season in dt_plotRefs$season) {
    
    list_export <- list(dateUpdated  = toNiceDate(dt_date_max[season==i_season]$date_max),
                        dataTable = dt_pointsTab[season==i_season],
                        plot = list(
                          frames = dt_pointsPlotData[season==i_season]$frames,
                          annotation = dt_plotRefs[season==i_season]$plotAnnotation,
                          yaxisAddIn = dt_plotRefs[season==i_season]$yaxisAddIn[[1]])
    )
    
    list_export |> 
      jsonlite::toJSON(auto_unbox = TRUE) |>
      write(file.path(path_source, "points.json"))
    
  }
  
  dt_cols |> 
    jsonlite::toJSON() |> 
    write(file.path(path_source, "points_columns.json"))
  
}
