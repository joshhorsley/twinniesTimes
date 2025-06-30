// import modules ------------------------------------------------

import { Link, useLoaderData } from "react-router-dom";

import { Container, Row } from "react-bootstrap";

import { TabView, TabPanel } from "primereact/tabview";

// import components ------------------------------------------------

import PageTitle from "../components/PageTitle";
import PointsPlotDynamic from "../components/PointsPlotDynamic";

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
        <h1>
          {season.season_display} Points Standing as of {season.dateUpdated}
        </h1>

        <TabView>
          <TabPanel header="" leftIcon="pi pi-chart-bar mr-2">
            <PointsPlotDynamic plotData={season.plot} />
          </TabPanel>

          <TabPanel header="" leftIcon="pi pi-table mr-2">
            {/* <PointsTable/> */}
          </TabPanel>

          <TabPanel header="Rules">
            <h3>Participation</h3>
            <ul>
              <li>15 points per Sprint race</li>
              <li>
                30 points per Double Sprint, Palindrome Tri race, or other
                special events
              </li>
            </ul>

            <h3>Handicap</h3>
            <ul>
              <li>Up to 15 points per Sprint race</li>
              <li>Must race with a timing chip</li>
              <li>
                Must start at your handicapped-based{" "}
                <Link to="/start-times">Start Time</Link>
              </li>
              <li>
                Must complete the course before 7:30 to beat your handicap time
                and be eligible for points
              </li>
              <li>
                Each race, the competitor to beat their handicap by the most
                time will receive 15 points, the second 14, the third 13, etc.
                for up to 15 racers
              </li>
              <li>
                New start times are allocated whenever handicap times are beaten
              </li>
            </ul>
          </TabPanel>
        </TabView>
      </Container>
    </>
  );
}
