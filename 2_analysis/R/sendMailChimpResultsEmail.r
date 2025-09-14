

sendMailChimpResultsEmail <- function(conn, target, mailChimpCred, test_address) {
  
  next_rego_available <- TRUE #
  
  date_nice <- "a date"
  
  subject_line <- glue(
    "Race Results for {date_nice}{subject_rego}",
    date_nice = date_nice,
    subject_rego = ifelse(next_rego_available," and Registrations Open","")
    )
  
  
  email_body <- glue(
    "Today's results are now <a href=\"{link_race_results_twinniestimes}\">online here</a><br>
  Check out the <a href=\"https://twinniestimes.netlify.app/points/\">Points Leaderboard</a><br>
  {registration_line}",
    link_race_results_twinniestimes = "https://twinniestimes.netlify.app/races/2025-03-22",
    registration_line = ifelse(
      next_rego_available,
      "Register for our next race via <a href=\"https://www.webscorer.com/33755?pg=register\">Webscorer</a><br>",
      "")
  )
  
  mailChimpSendEmail(
    campaign_title= "Race Results",
    subject_line = subject_line,
    email_title = subject_line,
    email_body = email_body,
    target = target,
    mailChimpCred = mailChimpCred,
    test_address = test_address
  )
  
}