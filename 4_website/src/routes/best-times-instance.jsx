// import modules ------------------------------------------------

import { useLoaderData } from "react-router-dom";
import { Container } from "react-bootstrap";
import { Popover, OverlayTrigger } from "react-bootstrap";

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
        {/* <h1 className="memberTitle"> */}
        <span>
          <span>
            <h1 className="memberTitle">
              Best Times {season.season_display && season.season_display + " "}
              <OverlayTrigger
                placement="bottom"
                overlay={
                  <Popover>
                    <Popover.Body>
                      {" "}
                      As of {season.dateUpdated}. <br></br>Best times for total
                      and individual laps. Lap and total times for each member
                      may not be from the same race, see all races details on
                      the linked member's page.
                    </Popover.Body>
                  </Popover>
                }
              >
                <span style={{ width: "fit-content" }}>&#9432;</span>
              </OverlayTrigger>
            </h1>
          </span>
        </span>

        {/* </h1> */}
        <BestTimesTable tabData={season.tabData} />
      </Container>
    </>
  );
}
