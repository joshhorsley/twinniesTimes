// import modules ------------------------------------------------

import { Link, useLoaderData } from "react-router-dom";

import { Container, Row } from "react-bootstrap";

import { TabView, TabPanel } from "primereact/tabview";

// import components ------------------------------------------------

import PageTitle from "../components/PageTitle";
import PointsPlotDynamic from "../components/PointsPlotDynamic";
import PointsTableDynamic from "../components/PointsTableDynamic";
import PointsRules from "../components/PointsRules";

// Component ------------------------------------------------

export default function PointsInstance() {
  // debugger;
  const { season } = useLoaderData();
  console.log("good 3");
  console.log(season);

  return (
    <>
      <PageTitle
        title={season.season_display ? "Points " + season.season_display : null}
      />
      {/* <PageTitle title = "points test"/> */}

      <Container>
        <h1 className="memberTitle">
          {season.season_display} Points Standing as of {season.dateUpdated}
        </h1>

        <TabView>
          <TabPanel header="" leftIcon="pi pi-chart-bar mr-2">
            <PointsPlotDynamic plotData={season.plot} />
          </TabPanel>

          <TabPanel header="" leftIcon="pi pi-table mr-2">
            <PointsTableDynamic tableData={season.dataTable} />
          </TabPanel>

          <TabPanel header="Rules">
           <PointsRules season={season.season}/>
          </TabPanel>
        </TabView>
      </Container>
    </>
  );
}
