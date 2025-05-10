dt_totalRacesOverall <- dt_dbReadTable(conn, "totalRacesOverall")


hist(dt_totalRacesOverall[races_full>1]$races_full)
hist(dt_totalRacesOverall[races_full>1]$races_full,breaks = c(0,1,5,25,50,100,200,300,400,500,600,700))
hist(dt_totalRacesOverall$races_full,breaks = c(0,1,5,25,50,100,200,300,400,500,600,700))


# dens

d <- density(dt_totalRacesOverall$races_full)

plot(d)

e <- ecdf(dt_totalRacesOverall$races_full)

d2 <- density(dt_totalRacesOverall[races_full>0]$races_full)

plot(d2)

rollsum(d2)


quantile(dt_totalRacesOverall$races_full,probs = c(0,0.25,0.5,0.75,0.9, 0.95, 0.975, 0.99, 0.995, 1)) |> 
  round(0)


# x <- 

e(seq(from = 50, to = 700, by = 50)) |> (\(x) (1-x)*nrow(dt_totalRacesOverall))()



dt_totalRacesSeason <- dt_dbReadTable(conn, "totalRacesSeason")

id_active <- dt_totalRacesSeason[season >= "2022-2023" & (races_all > 0)]$id_member



quantile(dt_totalRacesOverall[id_member %in% id_active]$races_full,probs = c(0,0.25,0.5,0.75,0.9, 0.95, 0.975, 0.99, 0.995, 1)) |> 
  round(0)
