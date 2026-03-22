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
          <ul>
            <li>Club Champs age categories and other awards vary by season, scroll horizontally to see more.</li>
            <li>As of 2025/26 The Presidents award was renamed to 'The  <a target="_blank" href="https://www.twintownstriathlon.org.au/former-members/">Kev Bannerman</a> Club Person of the Year'</li>
          </ul>
        <PeopleTable dataPeople={dataAwards} />
        </Container>
      </div>
    </>
  );
}
