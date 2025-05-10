dt_raceResults_check[season=="2024-2025" & distanceID=="sprint"][!is.na(Lap1), .(time = Lap1 |> min() |> seconds_to_hms_simple()), by = id_member][order(time)]
dt_raceResults_check[season=="2024-2025" & distanceID=="sprint"][!is.na(Lap2), .(time = Lap2 |> min() |> seconds_to_hms_simple()), by = id_member][order(time)]
dt_raceResults_check[season=="2024-2025" & distanceID=="sprint"][!is.na(Lap3), .(time = Lap3 |> min() |> seconds_to_hms_simple()), by = id_member][order(time)]
