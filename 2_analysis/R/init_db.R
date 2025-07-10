
init_db <- function(path_db) {
  
  if(exists("conn")) dbDisconnect(conn)
  
  
  if(file.exists(path_db)) unlink(path_db)
  
  path_dir <- dirname(path_db)
  if(!dir.exists(path_dir)) dir.create(path_dir, recursive = TRUE)
  
  conn <- dbConnect(RSQLite::SQLite(), path_db)
  dbExecute(conn, "PRAGMA foreign_keys=ON")
  
  
  dbExecute(conn, "CREATE TABLE seasons(
season TEXT PRIMARY KEY);")
  
  
  
  dbExecute(conn, "CREATE TABLE members(
id_member PRIMARY KEY,
name_last TEXT,
name_first TEXT,
name_display TEXT,
noLongerRacing INT,
totalRacesMetric TEXT,
twintownsMembershipID INT UNIQUE);")
  
  dbExecute(conn, "CREATE TABLE memberChips(
chip INT,
id_member,
date_assigned TEXT,
FOREIGN KEY(id_member) REFERENCES members(id_member) );") 
  
  
  dbExecute(conn, "CREATE TABLE memberChipLatest(
id_member PRIMARY KEY,
chip INT,
FOREIGN KEY(id_member) REFERENCES members(id_member) );") 
  
  
  
  
  
  dbExecute(conn, "CREATE TABLE committee(
season TEXT,
role TEXT,
id_member TEXT,
FOREIGN KEY(id_member) REFERENCES members(id_member),
FOREIGN KEY(season) REFERENCES seasons(season) );") 
  
  dbExecute(conn, "CREATE TABLE awards(
season TEXTT,
award TEXT,
id_member TEXT,
FOREIGN KEY(id_member) REFERENCES members(id_member),
FOREIGN KEY(season) REFERENCES seasons(season) 
            );") 
  
  
  
  dbExecute(conn, "CREATE TABLE distances(
distanceID PRIMARY KEY,
distanceDisplay TEXT,
otherNames TEXT,
parts TEXT);")
  
  dbExecute(conn, "CREATE TABLE races(
date_ymd PRIMARY KEY,
season TEXT,
special_event TEXT,
external TEXT,
start_time_change TEXT,
delay_points TEXT,
cancelled_reason TEXT,
FOREIGN KEY(season) REFERENCES seasons(season) 
);")
  
  
  
  
  dbExecute(conn, "CREATE TABLE totalRacesOverall(
  id_member TEXT,
  races_full INT,
races_all INT,
sprint INT,
aquabike INT,
tempta INT,
doubledistance INT,
doubleaquabike INT,
palindrometri INT,
palindromeaquabike INT,
swimrun INT,
riderun INT,
teams INT,
  FOREIGN KEY(id_member) REFERENCES members(id_member) );") 
  
  
  
  dbExecute(conn, "CREATE TABLE totalRacesSeason(
id_member TEXT,
season TEXT,
races_full INT,
races_all INT,
sprint INT,
aquabike INT,
tempta INT,
doubledistance INT,
doubleaquabike INT,
palindrometri INT,
palindromeaquabike INT,
swimrun INT,
riderun INT,
teams INT,
FOREIGN KEY(id_member) REFERENCES members(id_member),
FOREIGN KEY(season) REFERENCES seasons(season) 
);") 
  
  
  
  
  dbExecute(conn, "CREATE TABLE totalRacesDate(
id_member TEXT,
season TEXT,
date_ymd TEXT,
races_full INT,
races_all INT,
sprint INT,
aquabike INT,
tempta INT,
doubledistance INT,
doubleaquabike INT,
palindrometri INT,
palindromeaquabike INT,
swimrun INT,
riderun INT,
teams INT,
FOREIGN KEY(id_member) REFERENCES members(id_member),
FOREIGN KEY(season) REFERENCES seasons(season),
FOREIGN KEY(date_ymd) REFERENCES races(date_ymd)
);") 
  
  
  dbExecute(conn,"CREATE TABLE raceResults(
season TEXT,
date_ymd TEXT,
id_member TEXT NOT NULL,
distanceID TEXT,
Category TEXT,
teamID INT,
TimeTotal REAL,
Lap1 REAL,
Lap2 REAL,
Lap3 REAL,
Lap4 REAL,
Lap5 REAL,
Start REAL,
Split1 REAL,
Split2 REAL,
Split3 REAL,
Split4 REAL,
Split5 REAL,
chip INT,
NameProvided TEXT,
source TEXT,
FOREIGN KEY(date_ymd) REFERENCES races(date_ymd),
FOREIGN KEY(season) REFERENCES seasons(season), 
FOREIGN KEY(id_member) REFERENCES members(id_member),
FOREIGN KEY(distanceID) REFERENCES distances(distanceID)
            );")
  
  
  
  
  
  dbExecute(conn,"CREATE TABLE twintownMemberships(
  date_updated TEXT NOT NULL,
twintownsMembershipID INT,
nameTitle TEXT,
nameFirst TEXT,
nameLast TEXT,
phoneMobile INT,
phoneOther INT,
email TEXT,
date_dueMain TEXT,
date_dueTriathlon TEXT,
financial TEXT,
FOREIGN KEY(twintownsMembershipID) REFERENCES members(twintownsMembershipID)
            );")
  
  
  
  
  dbExecute(conn, "CREATE TABLE timesBestPoints(
  season TEXT,
date_ymd TEXT,
id_member TEXT NOT NULL,
TimeTotal REAL,
Category TEXT,
racedSprint,
timed,
timeBestSeason  REAL,
timeBestSeasonPrevious REAL,
timeBestSeasonAdjusted_carryForward REAL,
timeBestPreviousUse REAL,
nextStartThisSeason REAL,
hasAnyTimedSprintSeason,
nextStartNextSeason REAL,
date_ymd_next TEXT,
islaterSeason,
nextStartUse REAL,
comparableTimes,
timeDiff REAL,
handicapPoints_eligible,
timeDiffRank INT,
handicapPoints_give,
points_handicap_awarded INT,
points_participation_awarded INT,
points_marshal_awarded INT,
points_all_awarded INT,
points_all_total INT,
points_handicap_total INT,
points_particiation_total INT,
rank_all_total INT,
-- FOREIGN KEY(date_ymd) REFERENCES races(date_ymd),
FOREIGN KEY(season) REFERENCES seasons(season) ,
FOREIGN KEY(id_member) REFERENCES members(id_member)
  );")
  
  
  
  # Marshalling -------------------------------------------------------------
  
  
  
  
  dbExecute(conn, "CREATE TABLE marshalling(
date_ymd TEXT,
id_member TEXT,
FOREIGN KEY(id_member) REFERENCES members(id_member),
FOREIGN KEY(date_ymd) REFERENCES races(date_ymd)
);
            ")
  
  
  # Registrations -----------------------------------------------------------
  
  
  dbExecute(conn,"CREATE TABLE registrations(
  date_ymd TEXT NOT NULL,
  Bib TEXT,
  ChipId TEXT,
  Name TEXT,
  FirstName TEXT,
  LastName TEXT,
  Gender TEXT,
  Distance TEXT,
  Category TEXT,
  email TEXT,
  phone TEXT,
  RegistrationTime TEXT,
  email_permission TEXT,
  acknowledge_timing TEXT,
  acknowledge_roadRules TEXT,
  present TEXT,
  bestTimeSprintOverride INT,
  FOREIGN KEY(date_ymd) REFERENCES races(date_ymd)
)")  
  
  
  return(conn) 
  
  
}