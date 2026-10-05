

sendMailChimpResultsEmail <- function(
    conn,
    target,
    mailChimpCred,
    campaign_id,
    test_address
    ) {
  
  

# Latest date -------------------------------------------------------------


  dt_raceResults <- dt_dbReadTable(conn, "raceResults")
  
  date_use <- dt_raceResults[, max(date_ymd)]
  
  rm(dt_raceResults)
  
  date_nice <- date_use |> 
    as.Date() |> 
    (function(x) glue(
      '{date_day} {date_month}',
      date_day = day(x),
      date_month = month(x,label = TRUE)))()
  
  # season
  dt_races <- dt_dbReadTable(conn, "races")
  
  season_use <- dt_races[date_ymd==date_use, season]

  
# Assume next rego? -------------------------------------------------------

  
  is_club_champs <- dt_races[date_ymd==date_use, special_event %like% "Club Champs"]
  
  next_rego_available <- !is_club_champs
  

# Setup email parts -------------------------------------------------------

  
  subject_line <- glue(
    "Race Results for {date_nice}{subject_rego}",
    date_nice = date_nice,
    subject_rego = ifelse(next_rego_available," and Registrations Open","")
    )
  
  
  email_body <- glue(
    "Results for {date_nice} are now <a href=\"{link_race_results_twinniestimes}\">online here</a><br>
  Check out the <a href=\"https://twinniestimes.netlify.app/points/{season}\">Points Leaderboard</a><br>
  {registration_line}",
    date_nice = date_nice,
    link_race_results_twinniestimes = glue("https://twinniestimes.netlify.app/races/{date_ymd}", date_ymd = date_use),
    season = season_use,
    registration_line = ifelse(
      next_rego_available,
      "Register for our next race via <a href=\"https://www.webscorer.com/33755?pg=register\">Webscorer</a><br>",
      "")
  )
  

# Send --------------------------------------------------------------------
  
  
  mailChimpSendEmail(
    campaign_title = paste0("Race Results ", date_use),
    campaign_id = campaign_id,
    subject_line = subject_line,
    email_title = subject_line,
    email_body = email_body,
    target = target,
    mailChimpCred = mailChimpCred,
    test_address = test_address
  )
  
}