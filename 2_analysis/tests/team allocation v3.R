library(data.table)
library(multicool)
library(readxl)
library(lubridate)
library(english)

have_rego <- TRUE

list_pairs_avoid <- list(c("Tahlia Hughes","Oliver Hughes"),
                         c("GAP1","GAP2") # this stops a team from having only 1 person
                         )

dt_gap <- data.table(x = c(0,0),
                     name = c("GAP1","GAP2"))

n_pairs_avoid <- length(list_pairs_avoid)

# Load entries and prep times ---------------------------------------------


if(have_rego) {
  
  path_rego <- "data_files/2023-2024/races/2024-02-03/teams/3 Feb 2024 - Teams registrations TESTING.xls"
  
  dt_rego <- read_excel(path_rego) |> as.data.table()
  
  dt_rego <- dt_rego[, .(Bib = as.numeric(Bib), Name)]
  
  
  list_results <- readRDS("data_files/2023-2024/data_derived/list_results.rds")
  
  dt_best_times <- list_results$dt_season_results_all[(overall_valid) & Bib %in% dt_rego$Bib, .(Name =Name[1], best_time_mins = min(total_adjusted_seconds)/60), by = .(Bib, Distance)]
  
  
  dt_rego[dt_best_times[Distance=="Sprint"], on = .(Bib), best_time_mins := i.best_time_mins]
  dt_rego[, have_time := !is.na(best_time_mins)]
  
  
  ## Try adding from previous season if no results
  path_previous <- "data_files/previous_season_summary/previous_season_summary.xlsx"
  
  dt_previous <- read_excel(path_previous) |> 
    as.data.table()
  
  # drop any without chip numbers
  dt_previous <- dt_previous[!is.na(bib_2023)]
  
  dt_previous[, best_time_seconds_plus_3mins := best_time_2022_hms |> hms() |> seconds() |> as.numeric()]
  dt_previous[, best_time_seconds_plus_3mins := best_time_seconds_plus_3mins + 180]
  dt_previous[, bib_2023 := as.integer(bib_2023)]
  
  dt_previous[, have_time := FALSE]
  
  
  dt_rego[dt_previous, on = .(have_time, Bib = bib_2023), best_time_mins := i.best_time_seconds_plus_3mins/60 ]
  
  # Try adding from Tempta with adjusting factor
  dt_best_by_distance <- list_results$dt_season_results_all[(overall_valid)
                                                            , .(best_time = min(total_adjusted_seconds)), by = .(Bib, Distance)][
                                                              , .(best_time = mean(best_time)), by = .(Distance) 
                                                            ] |> 
    dcast.data.table(1 ~ Distance, value.var = "best_time") 
  
  
  tempta_ratio <- dt_best_by_distance$Sprint / dt_best_by_distance$Tempta / 0.95
  
  
  dt_best_times[,have_time := FALSE]
  dt_rego[dt_best_times[Distance=="Tempta"], on = .(Bib, have_time), best_time_mins := i.best_time_mins * tempta_ratio]
  dt_rego[, have_time := !is.na(best_time_mins)]
  
  stopifnot(all(dt_rego$have_time))
  
  # manual changes
  dt_rego[Name=="Kent Holmes", best_time_mins := 70]
  
  
  # check total number is divisible by 3
  n_total <- nrow(dt_rego)
  
  n_gaps <- (3 - (n_total - 3*(n_total %/% 3) )) %% 3
  
  
  n_teams <- ceiling(n_total/3)
  
  # format for allocation
  dt_test <- rbindlist(list(dt_rego[, .(x = best_time_mins,name = Name)],
                            dt_gap[seq(n_gaps)]))
  
}


# Setup test data ---------------------------------------------------------


if(!have_rego) {
  
  set.seed(0)
  
  n_total <- 39
  n_teams <- n_total/3
  
  x <- runif(n = n_total)*35+60
  dt_test <- data.table(x = x)
  dt_test[1:26, name := LETTERS]
  dt_test[-(1:26), name := letters[1:(n_total-26)]]
  
}

# Perform initial allocation ----------------------------------------------


how_many_groupings <- function(n,n_groups,n_size) factorial(n)/factorial(n_size)^n_groups/factorial(n_groups)

n_total_effective <- n_teams*3

n_options_all <- how_many_groupings(n_total_effective,n_teams,3)

sprintf("Have %i registrations (treated as %i), creating %i teams. There are %s possible arrangements!\n\nThat's %s options",
        n_total,
        n_total_effective,
        n_teams,
        format(n_options_all, scientific = FALSE, big.mark = ","),
        as.english(n_options_all)
) |> message()

#' allocate 1st and 3rd team members based on fastest + slowest, 2nd fastest + 2nd slowest ...
#' allocate middle based on fastest combined + slowest remaining

setorder(dt_test,x)

dt_test[1:n_teams, team := 1:n_teams]
dt_test[(n_teams*2+1):(3*n_teams), team := n_teams:1]

dt_test2 <- dt_test[!is.na(team), sum(x), by = team]
last_allocation <- dt_test2$V1 |> order()

dt_test[(n_teams+1):(2*n_teams), team := last_allocation]
dt_test[, x_sum := sum(x), by = team]

teams_with_GAP_initial <- dt_test[name %in% dt_gap$name]$team

dt_test[team %in% teams_with_GAP_initial, x_sum := 1.5*sum(x), by = team] 


# Prep for step-wise refinement -------------------------------------------


#' Compare swaps between fastest and slowest teams
#' Reallocate to minimise difference
#' 
#' Keep iterating until any of the following occur
#' - gap is under threshold
#' - max iterations reached
#' - gap does not change in sequential iterations


# Iteration options
threshold <- 1
iters_max <- 10


# Define possible permutations
x_refine = rep(1:(6/3), each = 3)
n_options <- multinom(x_refine) ## calculate the number of permutations
m = initMC(x_refine)
df_options <- allPerm(m)

# refine
# df_options2 <- 3 - df_options


# Initialise
iters <- 0
gap <- dt_test$x_sum |> range() |> diff()
message(sprintf("%2d - gap: %2.2f",iters,gap))

# Re-allocate
while(gap > threshold & iters < iters_max) {
  
  iters <- iters + 1
  
  # identify slowest and fastest teams
  dt_team_rank <- dt_test[, .(x_sum = x_sum[1]), by = team]
  
  # iterate fastest
  # for(i_team_outer in seq(n_teams-1)) {
  #   
  #   for(i_team_inner in (i_team_outer+1):n_teams) {
  #     message(paste0(i_team_outer, " - ", i_team_inner))
  #   }
  # }
  
  # iterate
  for(i_team_outer in seq(n_teams-1)) {
    
    
    teams_inner <- n_teams:(i_team_outer+1)
    
    teams_inner_use <- teams_inner[order(runif(length(teams_inner)))]
    
    
    # for(i_team_inner in n_teams:(i_team_outer+1)) {
    for(i_team_inner in teams_inner_use) {
          # message(paste0(i_team_outer, " - ", i_team_inner))
      
      team_slowest <- dt_team_rank[team==i_team_inner]$team
      team_fastest <- dt_team_rank[team==i_team_outer]$team
      
      # define swap options
      dt_swap_options <- dt_test[team %in% c(team_slowest,team_fastest)]
      
      dt_options <- data.table(opt = seq(n_options))
      
      # calculate total expected time of all options
      for(i_opt in seq(n_options)) {
        
        index_team_1 <- df_options[i_opt,]==1
        
        dt_options[i_opt, team1 := sum(dt_swap_options$x[index_team_1])]
        dt_options[i_opt, team2 := sum(dt_swap_options$x[!index_team_1])]
        
        # check for pairs to avoid
        team1_names <- dt_swap_options$name[index_team_1]
        team2_names <- dt_swap_options$name[!index_team_1]
        
        
        for(i_avoid in seq(n_pairs_avoid)) {
          
          team1_avoid <- all(list_pairs_avoid[[i_avoid]] %in% team1_names)
          
          if(team1_avoid) dt_options[i_opt, team1 := 10000]
          
          team2_avoid <- all(list_pairs_avoid[[i_avoid]] %in% team2_names)
          
          if(team2_avoid) dt_options[i_opt, team2 := 10000]
          
          # if(team1_avoid | team2_avoid) message("Avoided pairing")
        }
        
        if(any(dt_gap$name %in% team1_names)) dt_options[i_opt, team1 := 1.5 * team1]
        if(any(dt_gap$name %in% team2_names)) dt_options[i_opt, team2 := 1.5 * team2]
        
        
      }
      dt_options[, team_diff := team2 - team1]
      
      # re-allocate based on smallest difference in total
      which_alloc <- dt_options$team_diff |> abs() |> which.min()
      
      new_alloc <- c(team_slowest,team_fastest)[df_options[which_alloc,]]
      dt_test[team %in% c(team_slowest,team_fastest), team := new_alloc]
      
      # update team time
      new_times <- melt.data.table(dt_options[which_alloc, .(team1,team2)])[df_options[which_alloc,],value]
      dt_test[team %in% c(team_slowest,team_fastest), x_sum := new_times]
      # team 
      
      # update totals
      # dt_test[, x_sum := sum(x), by = team]
      gap_old <- gap
      gap <- dt_test$x_sum |> range() |> diff()
      
      
      # stop if no change
      # if(gap_old - gap < .Machine$double.eps) break
      
      
      
    }
    
    
  }
  message(sprintf("%2d - gap: %2.2f",iters,gap))
}

dt_out <- dt_test[,.(names = paste0(unlist(name),collapse = ", "),
                     expected_time = round(x_sum[1],1)), by = team][order(team)]

print(dt_out)
