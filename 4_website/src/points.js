import { matchSorter } from "match-sorter";
// import sortBy from "sort-by";

import pointsSeasonAll from "./data/pointsSeasonList.json"

export async function getPointsSeasons(query) {
  let pointsSeasons = structuredClone(pointsSeasonAll);
  if (query) { 
    // this isn't perfect
    // pointsSeasonAll.forEach(function(item, index) { pointsSeasons[index].options = matchSorter(item.options, query, {keys: ["season"]})});
  }

  return(pointsSeasons)
}

export async function getPointsSeason(value) {

  console.log(value)
  if (pointsSeasonAll.filter((season) => season.season == value).length == 0) { 
    throw new Response("", {
      status: 404,
      statusText: "Season not found"
    })
  }
  const response = await fetch('/data/points/' + value + '.json',{
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    }
  })
  
  const pointsData = await response.json();
  // debugger;
  console.log("good 1")
  console.log(pointsData)
  return pointsData ?? null;
}


// data loader
export async function pointsLoader({ params }) {
  const season = await getPointsSeason(params.pointsSeasonId);
  if(!season) {
    throw new Response("", {
      status: 404,
      statusText: "Season not found"
    })
  }
  console.log("good 2")
    console.log(season)
    return {season} ;
    
  }