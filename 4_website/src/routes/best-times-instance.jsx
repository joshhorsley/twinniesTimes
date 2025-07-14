// import modules ------------------------------------------------

import { useLoaderData } from "react-router-dom";
import { Container } from "react-bootstrap";

// import components ------------------------------------------------

import PageTitle from "../components/PageTitle";
import BestTimesTable from "../components/BestTimesTable";

// Component ------------------------------------------------

export default function BestTimesInstance() {
  const { season } = useLoaderData();

  return (
    <>
      <PageTitle
        title={
          season.season_display && "Best Times " + season.season_display[0]
        }
      />

      <Container>
        <h1 className="memberTitle">
          Best Times {season.season_display && season.season_display} as of{" "}
          {season.dateUpdated}
        </h1>
        <BestTimesTable tabData={season.tabData} />
      </Container>
    </>
  );
}
