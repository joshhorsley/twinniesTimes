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

      <Container>
        <h1 className="memberTitle">
          Total Races {season.season_display} as of {season.dateUpdated}
        </h1>

        <TotalRacesTable dataTotalRaces={season} />
      </Container>
    </>
  );
}
