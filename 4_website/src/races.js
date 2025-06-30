import { matchSorter } from "match-sorter";
// import sortBy from "sort-by";

import racesAllFlat from "./data/raceListFlat.json"
import racesAll from "./data/raceListHierarchy.json"

export async function getRaces(query) {
  let races = structuredClone(racesAll);
  if (query) { 
    // this isn't perfect
    racesAll.forEach(function(item, index) { races[index].options = matchSorter(item.options, query, {keys: ["date_ymd", "date_display", "extraNote"]})});
  }

  return(races)
}

export async function getRace(value) {

  if (racesAllFlat.filter((race) => race.date_ymd == value).length == 0) {
    throw new Response("", {
      status: 404,
      statusText: "Race not found"
    })
  }

  const response = await fetch('/data/races/' + value + '.json',{
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    }
  })

  const memberData = await response.json();

  return memberData[0] ?? null;
}


// data loader
export async function raceLoader({ params }) {
  const race = await getRace(params.raceId);
  
  if(!race) {
    throw new Response("", {
      status: 404,
      statusText: "Race not found"
        })
    }
    return { race };
  }