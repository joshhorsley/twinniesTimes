//  Packages --------------------------------------------------------

import { Container } from "react-bootstrap";

import PeopleTable from "../components/PeopleTable";
import PageTitle from "../components/PageTitle";

//  Data --------------------------------------------------------

import dataAwards from "../data/awards.json";

//  Component --------------------------------------------------------

export default function Awards() {
  return (
    <>
      <PageTitle title="Awards" />

      <div className="contentScroll">
        <Container>
          <h1>Awards</h1>

          <PeopleTable dataPeople={dataAwards} />
        </Container>
      </div>
    </>
  );
}
