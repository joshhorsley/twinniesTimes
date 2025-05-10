
//  Packages --------------------------------------------------------

import { Container} from 'react-bootstrap';
import { Link } from 'react-router-dom';

import { TabView, TabPanel } from 'primereact/tabview';

import PointsTable from '../components/PointsTable';

import PointsPlot from '../components/PointsPlot';

import PageTitle from "../components/PageTitle";


//  Data --------------------------------------------------------


import dataMain from "../data/points.json";


//  Component --------------------------------------------------------


export default function Points() {

return(
    <>
    <PageTitle title = "Points"/>


<div className="contentScroll">


        
<Container>


        <h1>2024/25 Points Standing as of {dataMain.dateUpdated}</h1>

    <TabView>
                <TabPanel header="" leftIcon="pi pi-chart-bar mr-2">
                    <PointsPlot />
                </TabPanel>

                <TabPanel header="" leftIcon="pi pi-table mr-2">
                    <PointsTable/>
                </TabPanel>

                <TabPanel header="Rules">
                <h3>Participation</h3>
    <ul>
        <li>15 points per Sprint race</li>
        <li>30 points per Double Sprint, Palindrome Tri race, or other special events</li>

    </ul>

    <h3>Handicap</h3>
    <ul>
        <li>Up to 15 points per Sprint race</li>
        <li>Must race with a timing chip</li>
        <li>Must start at your handicapped-based <Link to= "/start-times">Start Time</Link></li>
        <li>Must complete the course before 7:30 to beat your handicap time and be eligible for points</li>
        <li>Each race, the competitor to beat their handicap by the most time will receive 15 points, the second 14, the third 13, etc. for up to 15 racers</li>
        <li>New start times are allocated whenever handicap times are beaten</li>
    </ul>
                </TabPanel>
            </TabView>




</Container>

        </div>
    </>


)

}