import dataTotalRaces from "../data/totalRaces.json";
import { Container } from "react-bootstrap";

import PageTitle from "../components/PageTitle";

import TotalRacesTable from "../components/TotalRacesTables";

export default function TotalRaces() {
  return (
    <>
      <PageTitle title="Total Races" />

      <div className="contentScroll">
        <Container>
          <h1>Total races as of {dataTotalRaces.dateUpdated}</h1>
          <TotalRacesTable tabDataList={dataTotalRaces} />
        </Container>
      </div>
    </>
  );
}
