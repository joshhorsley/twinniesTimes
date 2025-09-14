import mailchimp_marketing as MailchimpMarketing
from mailchimp_marketing.api_client import ApiClientError


def pyCreateNewCampaign(title, subject_line, mailChimpCred):

  try:
    client = MailchimpMarketing.Client()
    client.set_config({
      "api_key":  mailChimpCred["api_key"],
      "server": mailChimpCred["server"]
    })
  
    response = client.campaigns.create({
      "type": "regular",
      "settings": {
        "subject_line": subject_line,
        "title": title
        }
        })
  except ApiClientError as error:
    print("Error: {}".format(error.text))
    
  
  return response


def py_mailChimpSetContent(campaign_id, content_html, mailChimpCred):

  try:
    client = MailchimpMarketing.Client()
    client.set_config({
      "api_key":  mailChimpCred["api_key"],
      "server": mailChimpCred["server"]
    })
  
    response = client.campaigns.set_content(campaign_id, {"html": content_html})
  except ApiClientError as error:
    print("Error: {}".format(error.text))
    
  return response


def py_mailChimp_test_email(campaign_id, test_emails, mailChimpCred):
 
  try:
    client = MailchimpMarketing.Client()
    client.set_config({
      "api_key":  mailChimpCred["api_key"],
      "server": mailChimpCred["server"]
    })

    response = client.campaigns.send_test_email(campaign_id, {"test_emails": [test_emails], "send_type": "html"})
  except ApiClientError as error:
    print("Error: {}".format(error.text))
    
    return response
  
