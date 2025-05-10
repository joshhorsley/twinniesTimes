dbGetQuery(conn, "SELECT id_member FROM marshalling")
dbGetQuery(conn, "SELECT id_member FROM committee WHERE season='2024-2025'")
(dt_champs <- dbGetQuery(conn,
"
SELECT DISTINCT name_first, name_last,
races_all AS Races,
ROUND(timeBest/60) AS [Best Time] FROM
(SELECT id_member FROM marshalling
UNION ALL
SELECT id_member FROM committee WHERE season='2024-2025') AS a
JOIN (SELECT id_member, races_all FROM totalRacesSeason WHERE season='2024-2025') AS b ON b.id_member=a.id_member
JOIN (SELECT id_member, name_last, name_first FROM members) AS m ON m.id_member=a.id_member
JOIN (SELECT id_member, timeBest FROM timesBestPoints WHERE date_ymd='2025-03-01') as t on t.id_member = a.id_member
WHERE races_all >5
ORDER by name_last, name_first
") |> 
  as.data.table()
)


hist(dt_champs$`Best Time`, breaks = 20,
     xlab = "Time (mins)",main = "Club Champs Best/Handicap times")
