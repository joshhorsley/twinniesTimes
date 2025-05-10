import {
    useLoaderData,
} from "react-router-dom";

import { getMember } from "../members";

import { Row, Container } from "react-bootstrap";

import { Link } from "react-router-dom";

import {Popover, OverlayTrigger } from "react-bootstrap";


import PageTitle from "../components/PageTitle";
import CardStats from "../components/cardstats";

import MemberPlot from "../components/MemberPlot";


// title

const popover = (
  <Popover id="popover-basic">
    <Popover.Body>Under construction</Popover.Body>
  </Popover>
);


  
export default function MemberInstance() {
    const {member} = useLoaderData();




  return (
    <>
    
    <PageTitle title = {member.name_display ? member.name_display : null}/>

      <Container>
        <h1 className="memberTitle">
          {member.name_last || member.name_last ? (
            <>
              {member.name_first} {member.name_last}
            </>
          ) : (
            <i>No Name</i>
          )}{" "}
        </h1>

        <Row>
          {/* <Col> */}
            <CardStats
                title = 'Chip'
                info = 'Most recent chip assigned. No result if chip later reassigned.'
                value = {member.chipLatest ? member.chipLatest : '-'}
                />
          {/* </Col> */}
          
          {/* <Col> */}
            <CardStats
              title = 'Sprint+ Races'
              info = 'Includes Sprint (previously Full) and Double Sprint events.'
              value = {member.racesFull ? member.racesFull : '-'}
            >
              <Link to="/total-races">Leaderboard</Link>
            </CardStats>
          {/* </Col> */}

{member.racesFull != member.racesTotal ?

            <CardStats
            title = 'All* Races'
            info = 'In addition to Sprint+, this includes Tempta (previously Intermediate), Aquabike, Swimrun, and Teams but records for these are not comprehensive.'
            value = {member.racesTotal ? member.racesTotal : '-'}
            >
              <Link to="/total-races">Leaderboard</Link>
            </CardStats> : ""
              }

         {member.committee[0]  ?  <CardStats
              title = "Committee"
              value = {member.committee[0].count}
              valueText = {member.committee[0].count > 1 ? " seasons" : " season"}
            >
              <Link to="/committee">View All</Link>


            </CardStats> : ""}
            </Row>

          {/* Change this to speciic flag */}
          {member.plot.barData ? (member.plot.barData.length  ? (

            

            <Row>
              <span>
                  <span>

                  <h2 style={{display: "inline-block"}}>
                  {'Races 2024/25' + ' ' } 
                <OverlayTrigger placement="top" overlay={popover}>
                  <span style={{width: "fit-content"}}>
                  &#9432;
                </span>
              </OverlayTrigger>
                  </h2>
</span>
                
              </span>
              <MemberPlot
                plotData={member.plot}/>
            </Row>
              ) : ("")) : ("")
}

        



        {member.notes && <p>{member.notes}</p>}


      </Container>
    </>
  );
  }