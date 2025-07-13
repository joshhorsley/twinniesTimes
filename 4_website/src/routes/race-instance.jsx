// import modules ------------------------------------------------

import { Link, useLoaderData } from "react-router-dom";

import { Container, Row } from "react-bootstrap";

// import components ------------------------------------------------

import PageTitle from "../components/PageTitle";
import CardStats from "../components/cardstats";
import RaceJointTablePlot from "../components/RaceJointTablePlot";

// Component ------------------------------------------------

export default function RaceInstance() {
  const { race } = useLoaderData();

  return (
    <>
      <PageTitle title={race.date_display ? race.date_display : null} />

      <Container>
        <h1 className="memberTitle">
          {race.date_display ? <>{race.date_display}</> : <i>No Name</i>}

          {/* Extra note */}
          {race.extraNote ? <>{` ${race.extraNote}`}</> : ""}
        </h1>

        <Row>
          {race.marshalling.length && (
            <CardStats title="Thanks to Marshals">
              <ul>
                {race.marshalling.map((e) => {
                  return (
                    <li key={e.id_member}>
                      <Link to={`/members/${e.id_member}`}>
                        {e.name_display}
                      </Link>
                    </li>
                  );
                })}
              </ul>
            </CardStats>
          )}

          {race.newcomers.length && (
            <CardStats title="First Timers">
              <ul>
                {race.newcomers.map((e) => {
                  return (
                    <li key={e.id_member}>
                      <Link to={`/members/${e.id_member}`}>
                        {e.name_display}
                      </Link>
                    </li>
                  );
                })}
              </ul>
            </CardStats>
          )}

          {race.milestones.length && (
            <CardStats title="Milestones">
              <ul>
                {race.milestones.map((e) => {
                  return (
                    <li key={e.id_member}>
                      <Link to={`/members/${e.id_member}`}>
                        {e.name_display}
                      </Link>{" "}
                      {e.races_use}
                    </li>
                  );
                })}
              </ul>
            </CardStats>
          )}

          {race.raceStats.n_entered && (
            <CardStats title="Finishers" value={race.raceStats.n_entered} />
          )}
          {race.raceStats.n_handicapAwards && (
            <CardStats
              title="Handicaps Points"
              value={race.raceStats.n_handicapAwards}
              valueText="racers"
            />
          )}
        </Row>

        {race.plot2 && (
          <RaceJointTablePlot
            plotData={race.plot2}
            tabData={race.tab2}
            tabDataTeams={race.tabData}
          />
        )}
      </Container>
    </>
  );
}
