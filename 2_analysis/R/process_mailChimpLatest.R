process_mailChimpLatest <- function(conn,
                                    path_log_dir,
                                    mailChimpCred,
                                    date_use
) {
  
  if(missing(mailChimpCred)) stop("Must provide mailchimp credentials")
  
  
  # Prep Python -------------------------------------------------------------
  
  
  use_condaenv("twinniesTimes")
  
  source_python("py/check_contact.py")
  
  
  # Load latest -------------------------------------------------------------
  
  
  if(missing(date_use)) {
    dt_reg <- dt_dbReadTable(conn, "registrations")[date_ymd==max(date_ymd)]
  } else {
    dt_reg <- dt_dbReadTable(conn, "registrations")[date_ymd==date_use]
  }
  
  
  # Prep --------------------------------------------------------------------
  
  
  # uniqueness  
  dt_reg[, email_occurance := seq(.N), by = email]
  dt_reg <- dt_reg[email_occurance==1]
  
  
  # Process -----------------------------------------------------------------
  
  
  # check if subscribed
  message("Checking status")
  dt_reg[, checkResponse := list(list(py_mailChimpContactCheck(email, mailChimpCred))),  by = email]
  dt_reg[, checkResponseStatus := checkResponse[[1]]$status, by= email]
  
  dt_reg[, addNewMember := checkResponseStatus =="404" & email_permission=="Y"]

  
  # add new members
  if(any(dt_reg$addNewMember)) {
    dt_reg[(addNewMember), addResponse := list(list(py_mailChimpcontactAdd(email, FirstName, LastName, mailChimpCred))), by = email]
    dt_reg[(addNewMember), addResponseCheck := addResponse[[1]]$status, by = email]
    
    dt_reg[, addNewProblem := (addNewMember) & addResponseCheck=="400"]
    
    
    if(any(dt_reg$addNewProblem)) {
      
      message("Add contact problems:")
      print(dt_reg[(addNewProblem)])
      print(dt_reg[(addNewProblem)]$addResponse)
    }
    
    n_added <- dt_reg[(addNewMember) & !addNewProblem] |> nrow()
    
    if(n_added>0) {
      message("Added")
      print(dt_reg[(addNewMember) & !addNewProblem, .(FirstName, LastName, email)])
    }
  }
  
  
  # Log ---------------------------------------------------------------------
  
  
  list_log <- list(all = dt_reg)
  
  date_register <- dt_reg$date_ymd[1]
  datetime_process <- Sys.time() |> format("%Y-%m-%d_%H-%M-%S_%Z")
  
  path_log <- file.path(path_log_dir, "mailChimp",
                        as.character(glue("{date_register} registrations - run at {datetime_process}.json")))
  
  write_json(list_log, path_log)
  
  message("Logged to ", path_log)
  
}