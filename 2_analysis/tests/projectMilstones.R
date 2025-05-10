# hat projections



# Load --------------------------------------------------------------------


dt_totalRacesOverall <- dt_dbReadTable(conn, "totalRacesOverall")

dt_totalRacesDate <- dt_dbReadTable(conn, "totalRacesDate")

dt_members <- dt_dbReadTable(conn, "members")
dt_members[, allRacesOverride := allRacesOverride==1]
dt_members[, noLongerRacing := noLongerRacing==1]

dt_races <- dt_dbReadTable(conn, "races")



# Options -----------------------------------------------------------------


longerTermThreshold <- 50L
n_week_project <- 50L
n_iters <- 2000L

milestones <- seq(from = 100, to = 800, by = 100)


# Prep --------------------------------------------------------------------


# races in last two seasons
dt_totalRacesDate[, raced_all := races_all != shift(races_all, 1), by = .(id_member)]
dt_totalRacesDate[is.na(raced_all), raced_all := TRUE]
dt_totalRacesDate[, raced_full := races_full != shift(races_full, 1), by = .(id_member)]
dt_totalRacesDate[is.na(raced_full), raced_full := TRUE]

dt_total_use <- dt_totalRacesDate[season >= "2023-2024"]

dt_total_use[dt_members, on = .(id_member), `:=`(totalRacesMetric = i.totalRacesMetric,
                                                 noLongerRacing = i.noLongerRacing)]

dt_total_use[, races_use := ifelse(totalRacesMetric=="full", races_full, races_all)]

# dt_total_use[, races_use := ifelse(races_full > races_all/2 & !(allRacesOverride), races_full, races_all)]
# dt_total_use[, raced_use := ifelse(races_full > races_all/2 & !(allRacesOverride), raced_full, raced_all)]
# 

dt_total_use[, longTermer := max(races_use) >= longerTermThreshold, by = .(id_member)]


dt_races[season >= "2023-2024" & is.na(cancelled_reason) , racesOrdinal := seq(.N)]

dt_total_use[dt_races, on = .(date_ymd), racesOrdinal := i.racesOrdinal]


date_lastRace <- dt_totalRacesDate$date_ymd |> max()
ordinal_lastRaces <- dt_races[date_ymd==date_lastRace]$racesOrdinal


# Active members ----------------------------------------------------------



dt_active <- dt_total_use[!(noLongerRacing), .(longTermer = longTermer[1],
                                               racesOrdinal_min = min(racesOrdinal),
                                               races_use_min = min(races_use),
                                               races_use_max = max(races_use))
                          , by = .(id_member)]


n_active <- nrow(dt_active)

dt_active[, raceRate := (races_use_max - races_use_min +1)/(ordinal_lastRaces - racesOrdinal_min+1)]


# Race life table ---------------------------------------------------------


ecdf_races <- ecdf(dt_totalRacesOverall$races_all)


# race drop-off for newcomers
dt_total_fractions <- data.table(i_race = seq(from = 1, to = max(dt_active[!(longTermer)]$races_use_max)+n_week_project+1))

dt_total_fractions[, fractionReact := 1 - ecdf_races(i_race -1)]
dt_total_fractions[1, fractionReact := 1]

dt_total_fractions[, probOneMore := shift(fractionReact, -1) / fractionReact]
dt_total_fractions <- dt_total_fractions[!is.na(probOneMore)]


# Simulation --------------------------------------------------------------


a_active_projection <- array(data = NA,
                             dim = c(
                               n_week_project,
                               n_active,
                               n_iters
                             ),
                             dimnames = list(seq(n_week_project),
                                             dt_active$id_member,
                                             seq(n_iters))
)

a_active_projection[1,,] <-  dt_active$races_use_max


projectNextRaceNewcomer <- function(x, race_rate) {
  x + (dt_total_fractions[x]$probOneMore*race_rate > runif(length(x)))*1
}

projectNextRaceLongtermer <- function(x, race_rate) {
  x + (race_rate > runif(length(x)))*1
}

ind_newcomer <- which(!dt_active$longTermer)
ind_longtermer <- which(dt_active$longTermer)

race_rate_newcomers <- dt_active[!(longTermer)]$raceRate
race_rate_longtermers <- dt_active[(longTermer)]$raceRate


##  run ------------------------------------
for(i_iter in seq(n_iters)) {
  
  
  for(i_row in seq(from = 2, to = n_week_project)) {
    
    
    a_active_projection[i_row,ind_newcomer,i_iter] <- projectNextRaceNewcomer(x = a_active_projection[i_row-1,ind_newcomer,i_iter],
                                                                              race_rate = race_rate_newcomers)
    
    a_active_projection[i_row,ind_longtermer,i_iter] <- projectNextRaceLongtermer(x = a_active_projection[i_row-1,ind_longtermer,i_iter],
                                                                                  race_rate = race_rate_longtermers)
  }
  
}

# check no NAs
stopifnot(!any(is.na(a_active_projection)))

# sum(is.na(a_active_projection))


# Summary -----------------------------------------------------------------



## race total by person and week -------------------------------------------


a_summary_person <- array(data = NA,
                          dim = c(
                            n_week_project,
                            n_active,
                            3
                          ),
                          dimnames = list(seq(n_week_project),
                                          dt_active$id_member,
                                          c("est","lci","uci"))
)

a_summary_person[,,"est"] <- apply(a_active_projection,MARGIN = c(1,2), mean)
a_summary_person[,,"lci"] <- apply(a_active_projection,MARGIN = c(1,2), quantile, probs = 0.025)
a_summary_person[,,"uci"] <- apply(a_active_projection,MARGIN = c(1,2), quantile, probs = 0.975)


# a_newcomers_projection_summary[,,]
# a_summary_person[n_week_project,,]


## by milestones and week -------------------------------------------------------------


n_milestones <- length(milestones)

a_milestonesTotal <- array(data = NA,
                           dim = c(n_week_project,
                                   n_milestones,
                                   n_iters),
                           dimnames = list(seq(n_week_project),
                                           milestones,
                                           seq(n_iters))
)

# for(i_milestone in seq(milestones)) {
#   
#   a_milestonesTotal[,i_milestone,] <- apply((a_active_projection > milestones[i_milestone])*1, MARGIN = c(1,3), sum)
#   
# }

for(i_milestone in seq(milestones)) {
  
  a_milestonesTotal[,i_milestone,] <- apply((a_active_projection > milestones[i_milestone])*1, MARGIN = c(1,3), sum)
  
}


# a_milestonesTotal[50,1,]

a_milestonesTotal_summary <- array(data = NA,
                                   dim = c(n_week_project,
                                           n_milestones,
                                           3),
                                   dimnames = list(seq(n_week_project),
                                                   milestones,
                                                   c("est","lci","uci"))
)

a_milestonesTotal_summary[,,"est"] <- apply(a_milestonesTotal,MARGIN = c(1,2), mean)
a_milestonesTotal_summary[,,"lci"] <- apply(a_milestonesTotal,MARGIN = c(1,2), quantile, probs = 0.025,)
a_milestonesTotal_summary[,,"uci"] <- apply(a_milestonesTotal,MARGIN = c(1,2), quantile, probs = 0.975)


dt_forcast_25 <- a_milestonesTotal_summary[25,,] |> as.data.table()
dt_forcast_25[, milestone := milestones]


dt_forcast_50 <- a_milestonesTotal_summary[50,,] |> as.data.table()
dt_forcast_50[, milestone := milestones]


## prob person reaches next milestone ----------------------------------


dt_active[, nextMilestone := milestones[cut(races_use_max+1, c(0,milestones),include.lowest = TRUE,labels = FALSE)]]

# dt_active[, probNextMilestone_25 = ]

frac_exceed <- function(x, thres) {
  mean(x > thres)
}

exceed_50 <- exceed_25 <- numeric(n_active)
for(i_member in seq(n_active)) {
  
  exceed_25[i_member] <- frac_exceed(
    a_active_projection[25,i_member,], 
    dt_active$nextMilestone[i_member]
  )
  
  exceed_50[i_member] <- frac_exceed(
    a_active_projection[50,i_member,], 
    dt_active$nextMilestone[i_member]
  )
}

dt_active[, probNextMilestone25 := exceed_25]
dt_active[, probNextMilestone50 := exceed_50]

# apply(a_active_projection[25,,], MARGIN = 1, frac_exceed, thres = dt_active$nextMilestone)


# setorder(dt_active, nextMilestone, probNextMilestone25, probNextMilestone50)



# apply(a_active_projection[25,,], MARGIN = 1, function(x) sum(x > dt_active$nextMilestone)/n_iters)



## By person overall ---------------------------------------------------------------


dt_forcast_person_25 <- a_summary_person[25,,] |> as.data.table()
dt_forcast_person_25[, id_member := dt_active$id_member]

dt_forcast_person_25[dt_active, on = .(id_member), n_current := races_use_max]

dt_forcast_person_25[, total_nice := glue("{est} ({lci}, {uci})",
                                          est = round(est,1),
                                          lci = round(lci,1),
                                          uci = round(uci,1))]

dt_forcast_person_25[, passed_nice := glue("{est} ({lci}, {uci})",
                                           est = round(est- n_current,1) ,
                                           lci = round(lci- n_current,1) ,
                                           uci = round(uci- n_current,1))]


dt_forcast_person_50 <- a_summary_person[50,,] |> as.data.table()
dt_forcast_person_50[, id_member := dt_active$id_member]
dt_forcast_person_50[dt_active, on = .(id_member), n_current := races_use_max]

dt_forcast_person_50[, total_nice := glue("{est} ({lci}, {uci})",
                                          est = round(est,1),
                                          lci = round(lci,1),
                                          uci = round(uci,1))]

dt_forcast_person_50[, passed_nice := glue("{est} ({lci}, {uci})",
                                           est = round(est- n_current,1),
                                           lci = round(lci- n_current,1),
                                           uci = round(uci- n_current,1))]


dt_active[dt_forcast_person_25, on = .(id_member), `:=`(total_est_25weeks = i.total_nice,
                                                        passed_est_25weeks = i.passed_nice)]

dt_active[dt_forcast_person_50, on = .(id_member), `:=`(total_est_50weeks = i.total_nice,
                                                        passed_est_50weeks = i.passed_nice)]


dt_active[dt_members, on = .(id_member), name_display := i.name_display]


# dt_active[, .(name  = name_display,
#               race_rate = round(raceRate,2),
#               total_current = races_use_max,
#               total_25weeks = total_est_25weeks,
#               total_50weeks = total_est_50weeks,
#               races_25weeks = passed_est_25weeks,
#               races_50weeks = passed_est_50weeks
#               
# )]

## Milestones so far -------------------------------------------------------


dt_active_by_season <- dt_total_use[!(noLongerRacing) & (raced_use),
                                    .(longTermer = longTermer[1],
                                      racesOrdinal_min = min(racesOrdinal),
                                      races_use_min = min(races_use)-1,
                                      races_use_max = max(races_use)
                                    ), by = .(id_member, season)]


dt_active_by_season[, row_id := seq(.N)]
# 
# 
dt_active_milestones <- CJ(row_id = dt_active_by_season$row_id,
                           milestone = milestones
                           )

# dt_active_milestones <- CJ(id_member = unique(dt_active_by_season$id_member),
#                            season = unique(dt_active_by_season$season),
#                            milestone = milestones)


dt_active_milestones[dt_active_by_season, on = .(row_id), `:=`(id_member = i.id_member,
                                                               season = i.season,
                                                               races_use_min = i.races_use_min,
                                                               races_use_max = i.races_use_max)]

# dt_active_milestones[dt_active_by_season, on = .(id_member, season), `:=`(
#   races_use_min = i.races_use_min,
#   races_use_max = i.races_use_max)]

# dt_active_milestones[, racedThisSeason := !is.na(races_use_min)]



# dt_active_milestones[, have_missing_season := any(is.na(c(races_use_min,races_use_max))), by = .(id_member)]
# 
# dt_active_milestones[(have_missing_season), `:=`(races_use_min = races_use_max[!is.na(races_use_min)],
#                                                  races_use_max = races_use_max[!is.na(races_use_max)]),
#                      by = .(id_member, milestone) ]


# this doesn't allow for whether they raced on the first day
# dt_active_milestones[, totalMilstone := races_use_max > milestone]
dt_active_milestones[,passedMilestone := races_use_min < milestone & races_use_max > milestone]


dt_milestones_summary_long <- dt_active_milestones[, .(#total = sum(totalMilstone, na.rm=TRUE),
                                                       passed = sum(passedMilestone, na.rm=TRUE)),
                                                   by = .(season, milestone)]

dt_milestones_summary_long[, season := ifelse(season=="2023-2024", "2023/24", "so_far_2024/25")]

# dt_milestones_summary <- dcast.data.table(dt_milestones_summary_long, milestone~season, value.var = "n_achieved")
dt_milestones_summary <- dcast.data.table(dt_milestones_summary_long, milestone~season, value.var = c("passed"))


# who passed

dt_past_milstones <- dt_active_milestones[(passedMilestone)]
dt_past_milstones[dt_members, on = .(id_member), name_display := i.name_display]


dt_past_milstonesDisplay <- dt_past_milstones[, .(season, milestone, name = name_display)]


# prep estimates

# dt_forcast_25[dt_milestones_summary, on = .(milestone), n_current := `i.total_so_far_2024/25`]
# 
# dt_forcast_25[, total_nice := glue("{est} ({lci}, {uci})",
#                                    est = round(est,1),
#                                    lci = lci,
#                                    uci = uci)]
# dt_forcast_25[, passed_nice := glue("{est} ({lci}, {uci})",
#                                     est = round(est - n_current,1),
#                                     lci = lci - n_current,
#                                     uci = uci - n_current)]
# 
# 
# dt_forcast_50[dt_milestones_summary, on = .(milestone), n_current := `i.total_so_far_2024/25`]
# 
# dt_forcast_50[, total_nice := glue("{est} ({lci}, {uci})",
#                                    est = round(est,1),
#                                    lci = lci,
#                                    uci = uci)]
# dt_forcast_50[, passed_nice := glue("{est} ({lci}, {uci})",
#                                     est = round(est - n_current,1),
#                                     lci = lci - n_current,
#                                     uci = uci - n_current)]
# 
# 
# dt_milestones_summary[dt_forcast_25, on = .(milestone), `:=`(total_est_25weeks = i.total_nice,
#                                                              passed_est_25weeks = i.passed_nice)]
# 
# dt_milestones_summary[dt_forcast_50, on = .(milestone), `:=`(total_est_50weeks = i.total_nice,
#                                                              passed_est_50weeks = i.passed_nice)]
# 
# 
# dt_milestones_summary[, .(milestone, `total_2023/24`,`total_so_far_2024/25`,total_est_25weeks,total_est_50weeks)]
# dt_milestones_summary[, .(milestone, `passed_2023/24`,`passed_so_far_2024/25`,passed_est_25weeks,passed_est_50weeks)]


## Probablity exceed next milestone ----------------------------------------


# chance of next milestone by person and milestone
dt_people_chance_next <- dt_active[, .(name = name_display,
                                       raceRate = round(raceRate,2),
                                       total_current = races_use_max,
                                       nextMilestone,
                                       `Total Est in 25 weeks` = total_est_25weeks,
                                       `Total Est in 50 weeks` = total_est_50weeks,
                                       `Probability reach in 25 weeks` = probNextMilestone25, 
                                       `Probability reach in 50 weeks` =  probNextMilestone50)
][order(-`Probability reach in 50 weeks`, -`Probability reach in 25 weeks`)]

# split(dt_people_chance_next, dt_people_chance_next$nextMilestone)


dt_people_chance_next_likely <- dt_people_chance_next[`Probability reach in 25 weeks` > 0.4 | `Probability reach in 50 weeks` > 0.4]

setorder(dt_people_chance_next_likely, -nextMilestone,-`Probability reach in 50 weeks`,-`Probability reach in 25 weeks`  )

# expected number of each milestone - prefer this one
dt_summary <- dt_people_chance_next[, .(
  `Expected within 25 races` = round(sum(`Probability reach in 25 weeks`),1),
  `Expected within 50 races` = round(sum(`Probability reach in 50 weeks`),1)
), by = .(milestone = nextMilestone)][order(milestone)]


dt_summary[dt_milestones_summary, on = .(milestone), `:=`(`During 2023/24` = `i.2023/24`,
                                                          `So far in 2024/25` = `i.so_far_2024/25`)]

setcolorder(dt_summary, c("milestone","During 2023/24","So far in 2024/25", "Expected within 25 races","Expected within 50 races"))

dt_totalHats <- dt_summary[, .(milestone,`From 2023/24 to 50 weeks` = `During 2023/24` + `So far in 2024/25` + `Expected within 50 races`)]


## hat totals -----------


# For report --------------------------------------------------------------

# expected
dt_totalHats

# milstone recent and forecast
dt_summary


# who passed in recent seasons
dt_past_milstonesDisplay[,.(milestone, name)] |> split(dt_past_milstonesDisplay$season)


# who is expected to pass soon
split(dt_people_chance_next_likely[, -c("nextMilestone")], dt_people_chance_next_likely$nextMilestone)

