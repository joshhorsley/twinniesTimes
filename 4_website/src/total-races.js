import { matchSorter } from "match-sorter";
// import sortBy from "sort-by";

import totalRacesSeasonAll from "./data/totalRacesSeasonList.json";

export async function getTotalRacesSeasons(query) {
  let totalRacesSeasons = structuredClone(totalRacesSeasonAll);
  if (query) {
    // this isn't perfect
    totalRacesSeasons = matchSorter(totalRacesSeasonAll, query, {
      keys: ["season"],
    });
  }
  return totalRacesSeasons;
}

export async function getTotalRacesSeason(value) {
  if (
    totalRacesSeasonAll.filter((season) => season.season == value).length == 0
  ) {
    throw new Response("", {
      status: 404,
      statusText: "Season not found",
    });
  }
  const response = await fetch("/data/totalraces/" + value + ".json", {
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
    },
  });

  const pointsData = await response.json();
  return pointsData ?? null;
}

// data loader
export async function totalRacesLoader({ params }) {
  const season = await getTotalRacesSeason(params.totalRacesSeasonId);
  if (!season) {
    throw new Response("", {
      status: 404,
      statusText: "Season not found",
    });
  }
  return { season };
}
