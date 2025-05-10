library(ggplot2)
library(lubridate)
library(ggrepel)

# plants_periods.tb <-
#   data.frame(Periods = c("seedling\nemergence",
#                          "treatment\nperiod"),
#              start = ymd(c("2020-05-06", "2020-06-22")),
#              end = ymd(c("2020-05-11", "2020-06-30")),
#              series = "Experiment 1")


range_buffer <- function(x, buffer_frac = 0.2) {
  
  r_x <- range(x, na.rm=TRUE)
  d_x <- diff(r_x) * buffer_frac
  
  c(r_x[1] - d_x,
    r_x[2] + d_x
    )
  
}


opposite <- function(x) -rev(x)

seconds_to_hms_simple <- function(x, drop_leading_0 = FALSE) {
  
  span <- as.double(x)
  remainder <- abs(span)
  hours_i <- remainder%/%(3600)
  remainder <- remainder%%(3600)
  minutes_i <- remainder%/%(60)
  seconds_i <- remainder%%(60)
  
  out <- ifelse(
    is.na(x),
    NA,
    sprintf("%01d:%02d:%02d", hours_i, minutes_i,seconds_i)
  )
  
  
  out
}


labels_from_seconds <- function(x) {
  
  seconds_to_hms_simple(x + 6*3600, TRUE)
}

axis_labels_from_seconds <- function(x) {
  
  seconds_to_hms_simple(x - 6*3600, TRUE)
}


plants.tb <-
  data.frame(what = c("Greg Freeman","Guy Davoren,  PersonB", "Val Lambard", "Dualex",
                      "Other Distances", "Alex Torrance", "Clive","Josh Horsley", "Matt Lance"),
             # when = ymd(c("2020-05-01", "2020-05-06", "2020-05-11", "2020-06-21",
             #              "2020-06-22", "2020-06-29", "2020-06-30")),
             # when = as.POSIXct(hms(c("6:00:00", "6:04:10", "6:04:20", "6:15:00",
             #              "6:15:15", "6:27:45", "6:34:01")), tz = ""),
             when = c(0,0.2, 1,10.2,15,24.75, 27.3,27.5,35.25)*60,
             # series = "Experiment 1")
             series = 0)
             # series = c(1,-1,))


# ggplot(plants.tb, aes(y = when, x = series)) +
ggplot(plants.tb, aes(y = -when, x = series)) +
  geom_line() +
  # geom_segment(data = plants_periods.tb,
  #              mapping = aes(x = start, xend = end,
  #                            y = series, yend = series,
  #                            colour = Periods),
  #              linewidth = 2) +
  geom_point() +
  geom_hline(yintercept = -15*60,linetype='dashed' ) +
  geom_label_repel(aes(label = glue("{time} {names}", time = labels_from_seconds(when), names = what)),
                   size = 7,
                  direction = "both",
                  point.padding = 0.5,
                  hjust = 0,
                  # max.overlaps = 0,
                  # vjust = 1,
                  box.padding = 1,
                  seed = 123
                  ,xlim = c(0.5,NA)
  ) + 
  # scale_y_datetime(name = "") +
  # scale_y_date(name = "", date_breaks = "1 months", date_labels = "%d %B",
  #              expand = expansion(mult = c(0.12, 0.12))) +
  scale_y_continuous(name= "",
                     limits = opposite(range_buffer(plants.tb$when)),
                     breaks = opposite(seq(from = 0, to = 40, by = 5)*60),
                     labels = axis_labels_from_seconds
                     ) + 
  scale_x_continuous(name = "", limits = c(0,2),breaks = NULL) +
  theme_minimal() +
  theme(axis.text=element_text(size=14)) +
  ggtitle("Sprint start timeline 12 Oct 2024")
  # theme(legend.position = "top")

ggsave("~/Desktop/test.pdf",units = "cm",width = 20,height = 28.7)
