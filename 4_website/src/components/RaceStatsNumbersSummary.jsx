import { SelectButton } from 'primereact/selectbutton';

import {Card } from 'react-bootstrap';
import { useState } from 'react';
import CardChange from './CardChange';

// import dataClubstats from "../data/clubMetrics.json";
import { Row } from "react-bootstrap";

// component ----------------------------------------------------------------------


export default function RaceStatsNumbersSummary({summaryCompare}) {
    const [comparePeriod, setComparePeriod] = useState("soFar");

    function onChange(e) {
        e.value ? setComparePeriod(e.value) : null
    }

return(
    <>
        Previous season comparison:
        <Row>
        <SelectButton
        // style={{width: "500px"}}
            allowEmpty = {false}
            value={comparePeriod}
            onChange={(e) => onChange(e)}
            optionLabel="name"
            options={[
                {name: "Same Period", value: "soFar"},
                {name: "Whole Season", value: "allWeeks"}
                
            ]}
            />
      

                <CardChange
                    title="Registrations"
                    value={summaryCompare[comparePeriod].registrations[0].current}
                    change={summaryCompare[comparePeriod].registrations[0].change}
                    previous={summaryCompare[comparePeriod].registrations[0].previous}
                    info="Average including cancelled races"
                    />

                <CardChange
                    title="Finishers"
                    value={summaryCompare[comparePeriod].finishers[0].current}
                    change={summaryCompare[comparePeriod].finishers[0].change}
                    previous={summaryCompare[comparePeriod].finishers[0].previous}
                    info="Average excluding cancelled races"

                    />
            </Row>

    </>
)

}