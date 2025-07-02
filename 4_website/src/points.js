import { matchSorter } from "match-sorter";
// import sortBy from "sort-by";

import pointsSeasonAll from "./data/pointsSeasonList.json";

export async function getPointsSeasons(query) {
  let pointsSeasons = structuredClone(pointsSeasonAll);
  if (query) {
    // this isn't perfect
        pointsSeasons = matchSorter(pointsSeasonAll, query, { keys: ["season"] });
  }
  return pointsSeasons;
}

export async function getPointsSeason(value) {
  if (pointsSeasonAll.filter((season) => season.season == value).length == 0) {
    throw new Response("", {
      status: 404,
      statusText: "Season not found",
    });
  }
  const response = await fetch("/data/points/" + value + ".json", {
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
    },
  });

  const pointsData = await response.json();
  return pointsData ?? null;
}

// data loader
export async function pointsLoader({ params }) {
  const season = await getPointsSeason(params.pointsSeasonId);
  if (!season) {
    throw new Response("", {
      status: 404,
      statusText: "Season not found",
    });
  }
  return { season };
}
