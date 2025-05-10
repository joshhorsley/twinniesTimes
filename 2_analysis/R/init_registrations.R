init_registrations <- function(conn,
                               path_webscorer,
                               question_mapping = list(
                                 email_permission = c("Do you agree to receive email updates from Twin Towns Tri Club?",
                                                      "Do you agree to receive email updates from Twinnies?"
                                 ),
                                 acknowledge_roadRules=c("Are you aware that you must follow road rules to race with Twin Towns Tri Club?"),
                                 acknowledge_timing=c("I understand that I must inform the timing desk if I don't complete the course or if my time is invalid for any reason because it will be automatically used to update handicaps and start times, assign points, and track PBs.")
                                 
                               )
) {
  
  dt_registrations <- dt_dbReadTable(conn, "races")[season>="2023-2024"]
  
  
  # Find all available ------------------------------------------------------
  
  
  dt_registrations[season=="2023-2024", path_dir_base := file.path(path_webscorer, season,"races" ,date_ymd, "1_INPUT_registration")]
  dt_registrations[season>"2023-2024", path_dir_base := file.path(path_webscorer, season ,date_ymd, "1_INPUT_registration")]
  
  dt_registrations[, path_results := list.files(path_dir_base, pattern = "xls$", full.names = TRUE), by = .(path_dir_base)]
  
  dt_registrations[!is.na(path_results), dt_rego := list(list(as.data.table(read_excel(path_results)))), by = path_results]
  setattr(dt_registrations$dt_rego, 'names', dt_registrations$path_results)
  
  
  # Load all available ------------------------------------------------------
  
  
  dt_registrations_All <- rbindlist(dt_registrations$dt_rego, fill = TRUE, idcol = "path_results")
  
  dt_registrations_All[dt_registrations, on = .(path_results), `:=`(date_ymd = i.date_ymd)]
  dt_registrations_All[, path_results := NULL]
  
  
  # Standardise questions ---------------------------------------------------
  
  
  # loop through all questions with defined mapping
  
  for(i_question in seq_along(question_mapping)) {
    
    q_i <- names(question_mapping)[i_question]
    dt_registrations_All[, (q_i) := character()]
    
    for(i_phrasing in seq_along(question_mapping[[i_question]])) {
      
      p_i <- question_mapping[[i_question]][i_phrasing]
      
      dt_registrations_All[is.na(dt_registrations_All[[q_i]]), (q_i) := get(p_i)]
    }
    
  }
  

# Teams specific ----------------------------------------------------------

  
  if("present" %notin% names(dt_registrations_All)) dt_registrations_All[, present := NA]
  if("bestTimeSprintOverride" %notin% names(dt_registrations_All)) dt_registrations_All[, bestTimeSprintOverride := NA]
  
  
  
  # Save --------------------------------------------------------------------
  
  
  dt_out <- dt_registrations_All[, .(date_ymd,
                                     Bib,
                                     ChipId = `Chip id`,
                                     Name,
                                     FirstName = `First name`,
                                     LastName = `Last name`,
                                     Gender,
                                     Distance,
                                     Category,
                                     email = tolower(Email),
                                     phone = `Phone #`,
                                     RegistrationTime = `Registration time`,
                                     email_permission,
                                     acknowledge_roadRules,
                                     acknowledge_timing,
                                     # extra vars for teams
                                     present = present,
                                     bestTimeSprintOverride = bestTimeSprintOverride
                                     
  )]  
  
  
  dbAppendTable(conn, "registrations", dt_out)
  
  
}


if(FALSE) {
  dt_registrations_All[, .(email_permisison,
                           `Do you agree to receive email updates from Twin Towns Tri Club?`,
                           `Do you agree to receive email updates from Twinnies?`)] |> 
    View()
}