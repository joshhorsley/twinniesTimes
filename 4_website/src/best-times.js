import { matchSorter } from "match-sorter";
// import sortBy from "sort-by";

import bestTimesSeasonAll from "./data/bestTimesSeasonList.json";

export async function getBestTimesSeasons(query) {
  let bestTimesSeasons = structuredClone(bestTimesSeasonAll);
  if (query) {
    // this isn't perfect
    bestTimesSeasons = matchSorter(bestTimesSeasonAll, query, {
      keys: ["season"],
    });
  }
  return bestTimesSeasons;
}

export async function getBestTimesSeason(value) {
  if (
    bestTimesSeasonAll.filter((season) => season.season == value).length == 0
  ) {
    throw new Response("", {
      status: 404,
      statusText: "Season not found 1",
    });
  }
  const response = await fetch("/data/besttimes/" + value + ".json", {
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
    },
  });

  const pointsData = await response.json();
  return pointsData ?? null;
}

// data loader
export async function bestTimesLoader({ params }) {
  const season = await getBestTimesSeason(params.bestTimesSeasonId);
  if (!season) {
    throw new Response("", {
      status: 404,
      statusText: "Season not found 2",
    });
  }
  return { season };
}
