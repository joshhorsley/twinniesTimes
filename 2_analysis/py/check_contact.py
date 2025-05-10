import mailchimp_marketing as MailchimpMarketing
from mailchimp_marketing.api_client import ApiClientError
import hashlib
import json


def py_mailChimpContactCheck(email, mailChimpCred):
  
  mailchimp = MailchimpMarketing.Client()
  mailchimp.set_config({
    "api_key": mailChimpCred["api_key"],
    "server": mailChimpCred["server"]
  })
  
  list_id = mailChimpCred["list_id"]
  
  member_email_hash = hashlib.md5(email.encode('utf-8').lower()).hexdigest()

  try: 
    response = mailchimp.lists.get_list_member(list_id, member_email_hash)
  except ApiClientError as error:
    response = json.loads(error.text)
    
  return response
  
def py_mailChimpcontactAdd(email,name_first, name_last , mailChimpCred):
  
  mailchimp = MailchimpMarketing.Client()
  mailchimp.set_config({
    "api_key": mailChimpCred["api_key"],
    "server": mailChimpCred["server"]
  })
  
  list_id = mailChimpCred["list_id"]
  
  member_info = {
    "email_address": email,
    "status": "subscribed",
    "merge_fields": {
      "FNAME": name_first,
      "LNAME": name_last
      }
    }
    
    
  try:
    response = mailchimp.lists.add_list_member(list_id, member_info)
  except ApiClientError as error:
    response = json.loads(error.text)
    
  return response


def py_mailChimpcontactUpdate(email, new_status, mailChimpCred):
  
  mailchimp = MailchimpMarketing.Client()
  mailchimp.set_config({
    "api_key": mailChimpCred["api_key"],
    "server": mailChimpCred["server"]
  })
  
  list_id = mailChimpCred["list_id"]
  
  member_update = {"status": new_status}
  
  member_email_hash = hashlib.md5(email.encode('utf-8').lower()).hexdigest()

    
  try:
    response = mailchimp.lists.update_list_member(list_id, member_email_hash, member_update)
  except ApiClientError as error:
    response = json.loads(error.text)
    
  return response


  
