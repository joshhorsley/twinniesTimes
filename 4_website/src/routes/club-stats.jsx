// packages ----------------------------------------------------------------------


import { Container } from "react-bootstrap";

import RaceStatsPlot from "../components/RaceMetricsPlot";
import PageTitle from "../components/PageTitle";
import LetterList from "../components/LetterList";

import RaceStatsNumbersSummary from "../components/RaceStatsNumbersSummary";

// data ----------------------------------------------------------------------


import dataClubstats from "../data/clubMetrics.json";


// component ----------------------------------------------------------------------


export default function ClubStats() {

    return(
        <>

        <PageTitle title="Club Stats"/>

        <Container className="contentScroll">

            <h1>Club Stats</h1>


            <h2>Numbers per race vs previous season</h2>

            <h3>Averages after {dataClubstats.numbersPerRace.summaryNumbers ? dataClubstats.numbersPerRace.summaryNumbers.weeksPassed: ""} weeks</h3>
                <RaceStatsNumbersSummary summaryCompare={dataClubstats.numbersPerRace.summaryNumbers.summaryCompare}/>

            <h3>By week</h3>
                Compare current season (blue) to previous (grey) registrations (dashed) and finishers (solid). Click/tap legend to show/hide.
                <br></br>
                <RaceStatsPlot plotPrep={dataClubstats.numbersPerRace.plotNumbers} />
                {dataClubstats.numbersPerRace.eventLetters ? <LetterList eventLetters = {dataClubstats.numbersPerRace.eventLetters} /> : ""}


        </Container>
        </>
    )
}