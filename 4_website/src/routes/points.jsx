//  Packages --------------------------------------------------------

import { Container } from "react-bootstrap";
import { Link } from "react-router-dom";

import { TabView, TabPanel } from "primereact/tabview";

import PointsTable from "../components/PointsTable";

import PageTitle from "../components/PageTitle";

//  Data --------------------------------------------------------

import dataMain from "../data/points.json";

//  Component --------------------------------------------------------

export default function Points() {
  return (
    <>
      <PageTitle title="Points" />

      <div className="contentScroll">
        <Container>
          <h1>2024/25 Points Standing as of {dataMain.dateUpdated}</h1>

          <TabView>
            <TabPanel header="" leftIcon="pi pi-table mr-2">
              <PointsTable />
            </TabPanel>
          </TabView>
        </Container>
      </div>
    </>
  );
}
