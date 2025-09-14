#' Sending marketing emails
#' defaults to sending to test email


mailChimpSendEmail <- function(
    path_email_template = "../email_templates/basic.html",
    campaign_title,
    subject_line,
    email_title="",
    email_body="",
    target = c("audience","test")[2],
    test_address,
    reply_address = "twintownstri@gmail.com",
    mailChimpCred
) {
  
  
  # Input checking ----------------------------------------------------------
  
  
  if(missing(campaign_title)) stop("Must provide a campaign title")
  if(missing(subject_line)) stop("Must provide a subject_line")
  if(target=="testing" & missing(test_address)) stop("Must provide a test email recipient if sending as test")
  if(missing(mailChimpCred)) stop("Must provide a mailChimpCred")
  stopifnot(target %in% c("audience","test"))
  
  
  # Setup new campaign ------------------------------------------------------
  
  
  response_create_campaign <- pyCreateNewCampaign(campaign_title, subject_line, mailChimpCred)
  
  have_campaign <- "id" %in% names(response_create_campaign)
  
  stopifnot(have_campaign)
  
  campaign_id <- response_create_campaign$id
  
  
  # Set content -------------------------------------------------------------
  
  
  html_template <- 
    path_email_template |> 
    readLines() |>
    paste0(collapse = "")
  
  html_filled <- glue(
    html_template,
    .open="{SUBSTART{",
    .close = "}SUBCLOSE}",
    email_title = email_title,
    email_body = email_body
  )
  
  response_content_set <- py_mailChimpSetContent(campaign_id, html_filled, mailChimpCred)
  
  
  # Send --------------------------------------------------------------------
  
  
  switch(target,
         "test" = py_mailChimp_test_email(campaign_id, test_address, mailChimpCred),
         "target" = stop("not ready yet")
         
  )
  
}