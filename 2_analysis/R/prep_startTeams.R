# how_many_groupings <- function(n,n_groups,n_size) factorial(n)/factorial(n_size)^n_groups/factorial(n_groups)
how_many_groupings <- function(n,n_groups,n_size) factorial(n)/factorial(n_size)^n_groups


prep_startTeams <- function(conn,
                            temptaRatio = 1.7,
                            list_pairs_avoid = list(
                              c("Kipp Freeman","Ginny Jones"),
                              c("Greg Freeman","Ginny Jones"),
                              c("Greg Freeman","Kipp Freeman"),
                              c("Tahlia Hughes","Oliver Hughes"),
                              c("Ben Wilkes","Rod Wilkes"),
                              c("Jamie Carruthers","Melissa Carruthers"),
                              c("Richard Mourant","James Mourant"),
                              c("GAP1","GAP2") # this stops a team from having only 1 person
                            ),
                            do_allocation = TRUE,
                            do_print = TRUE
) {
  
  
  # Load --------------------------------------------------------------------
  
  
  dt_reg <- dt_dbReadTable(conn, "registrations")[date_ymd==max(date_ymd)]
  date_ymd_use <- dt_reg[1]$date_ymd
  
  # dt_bestTimesSprint <-  dt_dbReadTable(conn, "timesBestPoints")[date_ymd==max(date_ymd) & timeBest < Inf][, .(id_member, timeBest)]
  dt_bestTimesSprint <- dt_dbReadTable(conn, "timesBestPoints")[date_ymd_next==date_ymd_use & nextStartUse < Inf, .(id_member, nextStartUse)]
  
  dt_resultsTempta <- dt_dbReadTable(conn, "raceResults")[season>="2024-2025" & distanceID =="tempta"]
  
  
  dt_memberChipLatest <- dt_dbReadTable(conn, "memberChipLatest")
  dt_memberChipLatest[, chip_character := as.character(chip)]
  
  
  # Prep --------------------------------------------------------------------
  
  
  dt_teams <- dt_reg[present =="y", .(Bib, Name, bestTimeSprintOverride)]
  
  # check there are 
  if(nrow(dt_teams)==0) {
    stop("No registraions with 'present' set to 'y' found for ", date_ymd_use,
         "\nCheck there is a column 'present' in the resgistraion file")
  }
  
  if(nrow(dt_teams)<6) {
    stop("Fewer than 6 'present' registrations found... probably need more to make teams")
  }
  
  
  
  dt_teams[dt_memberChipLatest, on = .(Bib = chip_character), id_member := i.id_member]
  
  dt_teams[dt_bestTimesSprint, on = .(id_member), nextStartUse := nextStartUse]
  
  # tempta
  dt_bestTimesTempta <- dt_resultsTempta[, .(timeBest = min(TimeTotal)), by = id_member]
  dt_teams[dt_bestTimesTempta, on = .(id_member), timeBestTempta := i.timeBest]
  
  dt_teams[, x := ifelse(is.na(nextStartUse), timeBestTempta * temptaRatio, nextStartUse)]
  
  dt_teams[!is.na(bestTimeSprintOverride), x := bestTimeSprintOverride]
  
  
  # check all times
  n_badTimes <- dt_teams[is.na(x) | is.infinite(x) ]
  stopifnot(n_badTimes==0)
  
  
  # add gaps if unbalanced
  dt_gap <- data.table(x = c(0,0),
                       Name = c("GAP1","GAP2"))
  
  n_total <- nrow(dt_teams)
  
  n_gaps <- (3 - (n_total - 3*(n_total %/% 3) )) %% 3
  
  
  n_teams <- ceiling(n_total/3)
  
  # format for allocation
  if(n_gaps>0) {
    
    dt_teams <- rbindlist(list(
      dt_teams,
      dt_gap[seq(n_gaps)]
    ),
    fill = TRUE)
  }
  
  
  # Allocation --------------------------------------------------------------
  
  if(do_allocation) {
    
    # n_total <- nrow(dt_teams)
    n_teams <- ceiling(n_total/3)
    
    n_total_effective <- n_teams*3
    n_options_all <- how_many_groupings(n_total_effective,n_teams,3)
    
    
    glue("Have {n_total} registrations (treated as {n_total_effective}), creating {n_teams} teams. There are {n_allocations_numeric} possible arrangements!\n\nThat's {n_allocations_english} options\n\n",
         n_allocations_numeric = format(n_options_all, scientific = FALSE, big.mark = ","),
         n_allocations_english = as.english(n_options_all)
         
    ) |> 
      message()
    
    
    ## Pairs avoid -------------------------------------------------------------
    
    
    n_pairs_avoid <- length(list_pairs_avoid)
    
    
    ## Initial -----------------------------------------------------------------
    
    
    setorder(dt_teams, x)
    
    dt_teams[1:n_teams, team := 1:n_teams]
    dt_teams[(n_teams*2+1):(3*n_teams), team := n_teams:1]
    
    dt_teamsInitial <- dt_teams[!is.na(team), .(x_sum = sum(x)), by = team]
    last_allocation <- dt_teamsInitial$x_sum |> order()
    
    dt_teams[(n_teams+1):(2*n_teams), team := last_allocation]
    dt_teams[, x_sum := sum(x), by = team]
    
    teams_with_GAP_initial <- dt_teams[Name %in% dt_gap$Name]$team
    
    dt_teams[team %in% teams_with_GAP_initial, x_sum := 1.5*sum(x), by = team] 
    
    
    ## Iterate allocation ------------------------------------------------------
    
    
    message("Iterating to minimise maximum expected gap between teams (~seconds in Sprint)")
    
    n_repeats <- 5L
    
    dt_repeats <- data.table(iteration = seq(n_repeats))
    
    # prep
    
    
    #' Compare swaps between fastest and slowest teams
    #' Reallocate to minimise difference
    #' 
    #' Keep iterating until any of the following occur
    #' - gap is under threshold
    #' - max iterations reached
    #' - gap does not change in sequential iterations
    
    
    # Iteration options
    threshold <- 1L
    iters_max <- 5L
    
    
    # Define possible permutations
    x_refine = rep(1:(6/3), each = 3)
    n_options <- multinom(x_refine) ## calculate the number of permutations
    m = initMC(x_refine)
    df_options <- allPerm(m)
    
    # refine
    # df_options2 <- 3 - df_options
    
    
    for(i_repeat in seq(n_repeats)) {
      
      message(glue("Rep {i_repeat}/{n_repeats}"))
      
      
      dt_teams_i <- copy(dt_teams)
      
      
      # Initialise
      iters <- 0
      gap <- (dt_teams_i$x_sum |> range() |> diff()) / 3
      message(sprintf("%2d - gap: %2.2f",iters,gap))
      
      
      ## loop  ------------------------------------------------------
      
      
      # Re-allocate
      while(gap > threshold & iters < iters_max) {
        
        iters <- iters + 1
        
        # identify slowest and fastest teams
        dt_team_rank <- dt_teams_i[, .(x_sum = x_sum[1]), by = team]
        
        
        # iterate
        for(i_team_outer in seq(n_teams-1)) {
          
          
          teams_inner <- n_teams:(i_team_outer+1)
          
          teams_inner_use <- teams_inner[order(runif(length(teams_inner)))]
          
          
          for(i_team_inner in teams_inner_use) {
            # message(paste0(i_team_outer, " - ", i_team_inner))
            
            team_slowest <- dt_team_rank[team==i_team_inner]$team
            team_fastest <- dt_team_rank[team==i_team_outer]$team
            
            # define swap options
            dt_swap_options <- dt_teams_i[team %in% c(team_slowest,team_fastest)]
            
            dt_options <- data.table(opt = seq(n_options))
            
            # calculate total expected time of all options
            for(i_opt in seq(n_options)) {
              
              index_team_1 <- df_options[i_opt,]==1
              
              dt_options[i_opt, team1 := sum(dt_swap_options$x[index_team_1])]
              dt_options[i_opt, team2 := sum(dt_swap_options$x[!index_team_1])]
              
              # check for pairs to avoid
              team1_names <- dt_swap_options$Name[index_team_1]
              team2_names <- dt_swap_options$Name[!index_team_1]
              
              
              for(i_avoid in seq(n_pairs_avoid)) {
                
                team1_avoid <- all(list_pairs_avoid[[i_avoid]] %in% team1_names)
                
                if(team1_avoid) dt_options[i_opt, team1 := Inf]
                
                team2_avoid <- all(list_pairs_avoid[[i_avoid]] %in% team2_names)
                
                if(team2_avoid) dt_options[i_opt, team2 := Inf]
                
                # if(team1_avoid | team2_avoid) message("Avoided pairing")
              }
              
              if(any(dt_gap$Name %in% team1_names)) dt_options[i_opt, team1 := 1.5 * team1]
              if(any(dt_gap$Name %in% team2_names)) dt_options[i_opt, team2 := 1.5 * team2]
              
              
            }
            dt_options[, team_diff := team2 - team1]
            
            # re-allocate based on smallest difference in total
            which_alloc <- dt_options$team_diff |> abs() |> which.min()
            
            new_alloc <- c(team_slowest,team_fastest)[df_options[which_alloc,]]
            dt_teams_i[team %in% c(team_slowest,team_fastest), team := new_alloc]
            
            # update team time
            new_times <- melt.data.table(dt_options[which_alloc, .(team1,team2)])[df_options[which_alloc,],value]
            dt_teams_i[team %in% c(team_slowest,team_fastest), x_sum := new_times]
            # team 
            
            # update totals
            # dt_test[, x_sum := sum(x), by = team]
            gap_old <- gap
            gap <- (dt_teams_i$x_sum |> range() |> diff()) / 3
            
            
            # stop if no change
            # if(gap_old - gap < .Machine$double.eps) break
            
            
            
          }
          
          
        }
        message(sprintf("%2d - gap: %2.2f",iters,gap))
      }
      
      
      
      dt_teamsAllocation <- dt_teams_i[,.(names = paste0(unlist(Name),collapse = ", "),
                                          timeCompare = round(x_sum[1]/3,0)), by = team][order(timeCompare)]
      
      dt_teamsAllocation[, team := seq(.N)]
      
      
      # print(dt_teamsAllocation)
      
      dt_repeats[i_repeat, `:=`(gap_i = gap, dt_teamsAllocation_i = list(list(dt_teamsAllocation)))]
      
    }
    
    dt_repeat_best <- dt_repeats[gap_i==min(gap_i)][1]
    # browser()
    
    message(glue("\n\n------------------------------\nBest allocation expected gap: {gap}s on Sprint", gap = round(dt_repeat_best$gap_i,0)))
    
    print(dt_repeat_best$dt_teamsAllocation_i[[1]][[1]])
    
    
  }
  
  # Print sheet -------------------------------------------------------------
  
  
  if(do_print) {
    
    
    ## import extra data for print list
    
    dt_raceInfo <- dt_dbReadTable(conn, "races")[date_ymd==date_ymd_use, .(start_time_change, season)]
    
    
    dt_totalRacesOverall <- dt_dbReadTable(conn, "totalRacesOverall")
    dt_totalRacesThisSeason <- dt_dbReadTable(conn, "totalRacesSeason")[season==dt_raceInfo$season]
    
    dt_members <- dt_dbReadTable(conn, "members")
    
    dt_marshals <- dt_dbReadTable(conn, "marshalling")[date_ymd==date_ymd_use]
    dt_marshals[dt_members, on = .(id_member), name_display := i.name_display]
    
    
    
    dt_start_print <- copy(dt_teams[Name %notin% dt_gap$Name])
    
    dt_start_print[dt_totalRacesOverall, on = .(id_member), `:=`(races_full = i.races_full,
                                                                 races_all = i.races_all)]
    
    dt_start_print[dt_totalRacesThisSeason, on = .(id_member), `:=`(races_all_this_season = i.races_all)]
    
    dt_start_print[, Distance := "Teams" ]
    
    
    
    # dt_start_print
    date_ymd_nice <- toNiceDate(date_ymd_use)
    
    ## paths ------------------
    
    paths_out <- list()  
    
    paths_out$dir_out <- file.path("../3_startLists", date_ymd_use)
    refreshDir(paths_out$dir_out)
    
    paths_out$print <- file.path(paths_out$dir_out,"print.xlsx")
    
    
    
    ## export -----------------
    
    wb <- export_printListTeams(dt_start_print, date_ymd_nice, dt_marshals)
    
    saveWorkbook(wb, paths_out$print, overwrite = TRUE)
    
    
  }
  
}