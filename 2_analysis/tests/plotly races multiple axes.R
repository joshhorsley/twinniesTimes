# example https://codepen.io/cerenoc/pen/wvVaYQj



# dt_prep_2024_2025[distanceID=="sprint" & Category=="Non-handicapped"][order(-y_plot), .(name_display, TimeTotal, y_plot, y_plot_compare =  frank(-TimeTotal,ties.method = "first"))]
# dt_prep_2024_2025[, y_plot := seq(.N), by =.(Category, distanceID)]

# Data --------------------------------------------------------------------




dt_json_prep <- dt_prep_2024_2025[, data.table(
  list(list(
    type='bar',
    orientation='h',
    # y=rev(seq(.N)),
    y=y_plot,
    base=Start,
    x=Lap1,
    name="Swim",
    legendrank= 3,
    yaxis= paste0("y", subplotID[1]),
    xaxis= paste0("x",  subplotID[1]),
    showlegend = showlegend[1],

    customdata = data.table(name_display = name_display,
                            distanceDisplay= distanceDisplay,
                            Category = Category,
                            startDispay = startDispay,
                            Lap1Display = Lap1Display,
                            Split1Display = Split1Display
    ),
    hovertemplate= "<b>%{data.name}: %{customdata.Lap1Display}</b><br><br>Started: %{customdata.startDispay}<br>Finished: %{customdata.Split1Display}<extra><b>%{customdata.name_display}</b><br><br>%{customdata.distanceDisplay}<br>%{customdata.Category}</extra>",
    
    marker=list(color="blue")
  )),
  
  list(list(
    type='bar',
    orientation='h',
    y=y_plot,
    base=Split1, # start
    x=Lap2Plot, # length
    name="Ride",
    legendrank= 2,
    yaxis= paste0("y",  subplotID[1]),
    xaxis= paste0("x",  subplotID[1]),
    showlegend = showlegend[1],
    
    customdata = data.table(name_display = name_display,
                            distanceDisplay = distanceDisplay,
                            Category = Category,
                            Lap2Display = Lap2Display,
                            Split1Display = Split1Display,
                            Split2Display = Split2Display,
                            Lap2PlotRunningTotalLabel = Lap2PlotRunningTotalLabel,
                            Lap2PlotRunningTotalDisplay = Lap2PlotRunningTotalDisplay),
    hovertemplate = "<b>%{data.name}: %{customdata.Lap2Display}</b><br>%{customdata.Lap2PlotRunningTotalLabel}: %{customdata.Lap2PlotRunningTotalDisplay}<br><br>Started: %{customdata.Split1Display}<br>Finished: %{customdata.Split2Display}<extra><b>%{customdata.name_display}</b><br>%{customdata.distanceDisplay}<br>%{customdata.Category}</extra>",
    marker=list(color="green")
  )),
  
  
  list(list(
    type='bar',
    orientation='h',
    y=y_plot,
    base=Split2Plot, # start
    x=Lap3Plot, # length
    name="Run",
    legendrank= 1,
    yaxis= paste0("y",  subplotID[1]),
    xaxis= paste0("x",  subplotID[1]),
    showlegend = showlegend[1],
    
    customdata = data.table(name_display = name_display,
                            distanceDisplay = distanceDisplay,
                            Category = Category,
                            Lap3Display = Lap3Display,
                            Split2Display = Split2Display,
                            Split3Display = Split3Display,
                            TimeTotalDisplay = TimeTotalDisplay),
    hovertemplate = "<b>%{data.name}: %{customdata.Lap3Display}</b><br><br>Started: %{customdata.Split2Display}<br>Finished: %{customdata.Split3Display}<extra><b>%{customdata.name_display}: %{customdata.TimeTotalDisplay}</b><br>%{customdata.distanceDisplay}<br>%{customdata.Category}</extra>",
    marker=list(color="red")
  ))
  
  
)
,by = .(distanceID, Category)
] |> 
  melt.data.table(id.vars = c("distanceID","Category"))



# Layout axes -------------------------------------------------------------



dt_dist_cat_unique[, domain_frac := (racers +2)/sum(racers)]
# dt_dist_cat_unique[domain_frac < 0.1, domain_frac := 0.1]
dt_dist_cat_unique[, domain_frac := domain_frac/sum(domain_frac)]


dt_dist_cat_unique[, domain_start := 1- ((cumsum(domain_frac)))]
dt_dist_cat_unique[, domain_stop := domain_start + domain_frac - 0.05]


dt_layout2 <- dt_dist_cat_unique[, data.table(
list(
  
    yaxis = list(domain = list(domain_start, domain_stop),
                 visible= FALSE),
    xaxis = list(showline = TRUE,
                 matches = "x",
                 anchor = paste0("y",subplotID)
               )
)
), by = .(subplotID)]

list_layout <- dt_layout2$V1

dt_names_axes <- CJ(subplotID = dt_dist_cat_unique$subplotID, axis = c("yaxis","xaxis") , sorted = FALSE)
dt_names_axes[, nameAxis := paste0(axis, subplotID)]

names(list_layout) <- dt_names_axes$nameAxis




# Name and points annotations ---------------------------------------------


## Distance/Category -------------------------------------------------------



dt_dist_cat_unique[dt_distances, on = .(distanceID), distanceDisplay := i.distanceDisplay]
dt_dist_cat_unique[, classInDistance := .N, by = distanceID]

dt_annotations_distances <- dt_dist_cat_unique[, data.table(
  list(list(
    x = 0.01,
    xanchor = "left",
    y = domain_stop,
    yanchor = "bottom",
    font = list(size = 20),
    xref = paste0("x",subplotID),
    yref = "paper",
    text = ifelse(classInDistance==1,distanceDisplay, paste0(distanceDisplay, " - ", Category)),
    showarrow = FALSE
    
  ))
), by = subplotID]


# list_annotations <- dt_annotations_distances$V1



## Name/finish
dt_annotations_racers <- dt_prep_2024_2025[, data.table(
  list(list(
    x = Start + TimeTotal + 120 +0.001,
    xanchor = "left",
    y = y_plot + 0.001,
    yanchor = "middle",
    font = list(size = "15",
                color = racerAnnotationColor),
    xref = paste0("x",subplotID),
    yref = paste0("y",subplotID),
    text = racerAnnotation,
    showarrow = FALSE
  )
  )
), by = id_member]

# dt_annotations_racers$V1

list_annotations <- append(dt_annotations_distances$V1,
                           dt_annotations_racers$V1)

# Save --------------------------------------------------------------------


list_export <- list(plot = list(data =  dt_json_prep$value,
                                layoutAxes = list_layout,
                                layoutAnnotations = list(annotations = list_annotations)))


json_prep <- list_export |> 
  toJSON(auto_unbox=TRUE, pretty = TRUE) |> 
  
  # restore boxing to numeric vectors when only one in group - needed for data
  gsub(pattern = ": ([0-9]+),",
       replacement = ": \\[\\1\\], ") |>

  # remove boxing from legendrank
# gsub(pattern = "\"legendrank\": \\x5B([0-9])\\x5D", replacement ="\"legendrank\": \\1" ,x = '"legendrank": [1]') 
gsub(pattern = "\"legendrank\": \\x5B([0-9])\\x5D", replacement ="\"legendrank\": \\1") 


# remove boxing for annotations
# THis is very dodgy fix because the y values are only saved by begin decimal values!
# exploted this to work with x!

# for(i_rep in seq(nrow(dt_annotations)*2)) {
#   json_prep <-   gsub(pattern = "(\"x\": )\\[([(0-9)])\\](,.*[\\s|\n]+\"xanchor)", replacement ="\\1\\2\\3", x =json_prep, perl = TRUE)
# }


# |>
  
  # remove boxing from annotations
  
  
  write(json_prep, file.path(pathsWebsiteData$source, "TESTraceData.json"))

# 
# gsub(pattern = " [0-9]")
#   
#   
#   # can't seemto find a way to get single square brackets, unlist(recursive= FALSE) removes both
#   gsub(pattern = "^\\[|\\]$",replacement = "") |>
#   trimws() |> 
#   write(file.path(pathsWebsiteData$source, "TESTraceData.json"))
#   


  gsub(pattern = "(\"x\": )\\[([(0-9)])\\](,.*[\\s|\n]+\"xanchor)", replacement ="\\1\\2\\3", x ='"x": [0],
       "xanchor"', perl = TRUE)
  gsub(pattern = "\"x\": \\x5B[0-9]\x50", replacement ="REPLACED", x ='"x": [0]', perl = TRUE)
  
  
x <-  ' this is text layoutAnnotations lsdfjsajh 12312 [] "x": [0], "x": [0]  [0]'

cat(x <- gsub(pattern = "(layoutAnnotations.*)\\x5B([0-9])\\x5D(.*)", replacement ="\\1 0 \\3", x =x, perl = TRUE))



gsub(pattern = "\"layoutannotation\": .* \\x5B([0-9])\\x5D", replacement ="\"legendrank\": \\1", x = 'layoutAnnotations lsdfjsajh 12312 [] "x": [10] ') |> cat()
