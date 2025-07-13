// import modules ------------------------------------------------

import { useLoaderData } from "react-router-dom";
import { Container } from "react-bootstrap";

// import components ------------------------------------------------

import PageTitle from "../components/PageTitle";
import TotalRacesTable from "../components/TotalRacesTables";

// Component ------------------------------------------------

export default function TotalRacesInstance() {
  const { season } = useLoaderData();
  return (
    <>
      <PageTitle
        title={
          season.season_display ? "Total Races " + season.season_display : null
        }
      />
      {/* <PageTitle title = "points test"/> */}

      <Container>
        <h1 className="memberTitle">
          Total races for {season.season_display} as of {season.dateUpdated}
        </h1>

        <TotalRacesTable dataTotalRaces={season} />
      </Container>
    </>
  );
}
