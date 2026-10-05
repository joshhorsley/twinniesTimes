dt_totalRacesSeason <- dt_dbReadTable(conn, "totalRacesSeason")
dt_races <- dt_dbReadTable(conn, "races")
dt_raceResults <- dt_dbReadTable(conn, "raceResults")

dt_raceCountPerSeason <- dt_raceResults[,.(n_racesWithResults = length(unique(date_ymd))), by = season]

dt_seasonTrends <- dt_totalRacesSeason[, .(finishers = sum(races_all)), by = season][order(season)]


dt_seasonTrends[dt_raceCountPerSeason, on = .(season), n_racesWithResults := i.n_racesWithResults]


dt_seasonTrends[is.na(n_racesWithResults), n_racesWithResults := 26]

dt_seasonTrends[, finishersPerRace := finishers/n_racesWithResults]


library(ggplot2)


dt_seasonTrends[, season_year_start := substr(season, 1,4) |> as.numeric()]
dt_seasonTrends[, location := fifelse(season_year_start>=2022, "South Tweed","Banora")]

 attr(dt_seasonTrends$location, "label") <- "Location"
 attr(dt_seasonTrends$finishersPerRace, "label") <- "Finishers per race (season average)"
 attr(dt_seasonTrends$season_year_start, "label") <- "Year (season start)"

ggplot(
  dt_seasonTrends,
  aes(
    x = season_year_start,
    y = finishersPerRace,
    color = location,
    group = location
  )
) +
  # annotate(
  #   "rect",
  #   fill = "orange",
  #   alpha = 0.2,
  #   xmin = 2022,
  #   xmax = max(dt_seasonTrends$season_year_start),
  #   ymin = min(dt_seasonTrends$finishersPerRace),
  #   ymax = max(dt_seasonTrends$finishersPerRace)
  # ) +
  # geom_smooth(method = "gam") +
  geom_point() +
  geom_line() +
  scale_x_continuous(
    breaks = seq(from = 1990, to = max(dt_seasonTrends$season_year_start), by = 5)
    ) +
  scale_y_continuous(
    limits = c(0,NA),
    breaks = seq(from = 0, to =  max(dt_seasonTrends$finishersPerRace), by = 10),
    sec.axis = sec_axis(~., breaks = seq(from = 0, to =  max(dt_seasonTrends$finishersPerRace), by = 10))
                     ) +
  ggtitle("Finisher per race by season") +
  theme_minimal() +
  theme(legend.position = "top")
  

# geom_smooth()


plot(
  dt_seasonTrends$finishersPerRace,
  type= "l",
  ylim = c(0, max(dt_seasonTrends$finishersPerRace))
)
# dt_races[is.na(cancelled_reason), .N, by = season][season < "2024-2025"]



