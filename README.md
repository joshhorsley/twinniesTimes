# Twinnies Times

This project automates the processing of results, related stats, and admin tasks for [Twin Towns Tri Club](https://www.twintownstriathlon.org.au) mostly in R,  including:

- Generation and publication of the [result webpage](https://twinniestimes.netlify.app) - mostly in ReactJS
- Creation of start lists - for print out and pre-formatted for Webscorer automated timing
- Management of Mailchimp mailing lists and sending result emails via API


# Setup

1. Create soft link (or copy) of `1_dataProvided` on google drive to base directory
1. Install R dependencies in `2_analysis` using `renv::restore()` - note that XLConnect requires [java](https://www.java.com/en/)
1. Install Python 3.13.7 or higher and setup project library from `2_analysis` using `setup_python.r`
1. Install npm and from `4_website` run `npm install`

# Processing results

From `2_analysis` run `main.R`. This creates an sqlite database in `3_data_derived` and json files within `4_website`

# Preparing start list

After sourcing `main.R`,

For regular events: run `prep_startLatest()`

- This creates excel files in `3_startLists`
    - a print out for the timing desk
    - a start list file for the webscorere windows desktop app

For teams events: run `prep_startTeams()`


# Updating website

Run website testing and publish from `4_website` running commands

- `npm run dev` for local testing
- `npm run pub` to publish to netlify - this requires authentication


# Mailchimp

## Updating audience mailing list

After sourcing `main.R` run `process_mailChimpLatest()`

## Sending out results email

After sourcing `main.R` run `mailChimpSendEmail()`

This function defaults to sending a test version to the address specified in `1_dataProvided\privateKeys.json`



