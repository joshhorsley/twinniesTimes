
import { Container } from "react-bootstrap";


import PageTitle from "../components/PageTitle";


import dataHome from "../data/home.json"


// Component ------------------------------------------------------


export default function Home() {

    return(
        <>
        <PageTitle/>


        <Container className="contentScroll">
            <p>Results and stats for <a target="_blank" href="https://www.twintownstriathlon.org.au">Twin Towns Tri Club</a></p>

            <p>Last updated {dataHome.dateUpdate}</p>

        </Container>
        </>
    )
}