//  Packages --------------------------------------------------------

import { Container } from "react-bootstrap";

import PeopleTable from "../components/PeopleTable";
import PageTitle from "../components/PageTitle";

//  Data --------------------------------------------------------

import dataCommittee from "../data/committee.json";

//  Component --------------------------------------------------------

export default function Committee() {
  return (
    <>
      <PageTitle title="Committee" />

      <div className="contentScroll">
        <Container>
          <h1>Committee</h1>
          Some incomplete records between 1995/96 and 2002/03.
          <PeopleTable dataPeople={dataCommittee} />
        </Container>
      </div>
    </>
  );
}
