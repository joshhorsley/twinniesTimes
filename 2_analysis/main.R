
# prep database -----------------------------------------------------------


# Packages ----------------------------------------------------------------


library(RSQLite)
library(data.table)
library(readxl)
library(zoo)
library(lubridate)
library(glue)
library(jsonlite)
library(XLConnect)
library(openxlsx)
library(reticulate)
library(english)
library(multicool)


# Functions ---------------------------------------------------------------


invisible(
  lapply(list.files("R", full.names = TRUE),
         source
  )
)


# Paths -------------------------------------------------------------------


# Check that dataProvided exists
#' 1_dataProvied can be set with a soft link to the google drive path `/Timing Files/1_dataProvided`
if(!dir.exists("../1_dataProvided")) {
  stop("Cannot locate dataProvided directory")
}

paths <- list(
  private = "../1_dataProvided/privateKeys.json",
  db = "../3_data_derived/all_results.sqlite",
  manual = "../1_dataProvided/manual.xlsx",
  webscorer = "../1_dataProvided/webscorer",
  dir_twintownMemberships = "../1_dataProvided/twintownMembership",
  dir_log = "../logs"
)


# PrivateKeys -------------------------------------------------------------


privateKeys <- loadPrivateKeys(paths$private)

  
# Initialise db -----------------------------------------------------------


conn <- init_db(paths$db)


# Race info ---------------------------------------------------------------


init_seasons(conn, paths$manual)
init_races(conn, paths$manual)
init_distances(conn, paths$manual)


# Create race directories -------------------------------------------------


# directories to store registration and result files from webscorer
create_webscorer_directories(conn, paths$webscorer)


# Member info -------------------------------------------------------------


init_members(conn, paths$manual)
init_membersChips(conn, paths$manual)
init_memberChipLatest(conn)

init_twinTownsMembers(conn,
                      path_dir_twintownMemberships = paths$dir_twintownMemberships,
                      members_pass = privateKeys$twintownsMembership$spreadsheetPass) # why does this trigger log warning?
init_committee(conn, paths$manual)
init_awards(conn, paths$manual)
init_marshalling(conn, paths$manual)


# Results -----------------------------------------------------------------


init_RaceResultsOldWebscorer(conn, paths$webscorer)
init_raceResultsWebscorer2023_2024(conn, paths$webscorer)
init_raceResultsWebscorerNew(conn, paths$webscorer)

init_raceResultsParticipationManual(conn, paths$manual)
init_raceResultsTeams(conn, paths$manual)


# Result summaries --------------------------------------------------------


# total races
init_totalRaces(conn, paths$manual)

# points/start times/PBs
init_startTimesAndPoints(conn, paths$manual)


# Registrations -----------------------------------------------------------


init_registrations(conn, paths$webscorer)


# Prep website data -------------------------------------------------------


if(!exists("conn")) {
  conn <- dbConnect(RSQLite::SQLite(), paths$db)
}


## Colours ----------------------------------------------------------------


tri_cols <- list(pb = "pink",
                 record = "gold",
                 invalid = "grey",
                 swim = "#2E63BC",
                 ride = "#3B8544",
                 run = "#BF5324",
                 club_1 = "#31b5b2",
                 club_2 = "#1a1a18",
                 club_3 = "#b71469"
)


# Paths -------------------------------------------------------------------


# paths
pathsWebsiteData <- list(
  public = "../4_website/public/data",
  source = "../4_website/src/data"
)

pathsWebsiteData$memberData <- file.path(pathsWebsiteData$public, "members")
pathsWebsiteData$raceData <- file.path(pathsWebsiteData$public, "races")
pathsWebsiteData$pointsData <- file.path(pathsWebsiteData$public, "points")
pathsWebsiteData$totalRacesData <- file.path(pathsWebsiteData$public, "totalraces")
pathsWebsiteData$bestTimesData <- file.path(pathsWebsiteData$public, "besttimes")

clearWebsiteData(pathsWebsiteData)


# Prep JSON ---------------------------------------------------------------


prepJson_main(conn, pathsWebsiteData$source)
prepJson_home(pathsWebsiteData$source)
prepJson_startTimesAll(conn, pathsWebsiteData$source)

prepJsonTotalRaces(conn, pathsWebsiteData$source, pathsWebsiteData$totalRacesData)
prepJsonBestTimesData(conn, pathsWebsiteData$source, pathsWebsiteData$bestTimesData)
prepJsonPoints(conn, pathsWebsiteData$pointsData, pathsWebsiteData$source, tri_cols)

prepJsonMemberData(conn, pathsWebsiteData$source, pathsWebsiteData$memberData)
prepJsonRaceData(conn, pathsWebsiteData$source, pathsWebsiteData$raceData)

prepJsonClubMetrics(conn, pathsWebsiteData$source)
prepJsonCommittee(conn, pathsWebsiteData$source)
prepJsonAwards(conn, pathsWebsiteData$source)


# Process registrations ---------------------------------------------------


if(FALSE) {
  prep_startLatest(conn)
  process_mailChimpLatest(conn, paths$dir_log, privateKeys$mailChimp)
  quarto::quarto_render("docs/membership.qmd")
  # prep_membershipPrintout(conn)
  prep_startTeams(conn, do_print = TRUE, do_allocation = FALSE)
}

