import {
    Outlet,
    NavLink,
    useLoaderData,
    Form,
    // redirect,
    useNavigation,
    useSubmit
} from "react-router-dom";

import { Row } from "react-bootstrap";

import {getRaces} from "../races";
import { useEffect } from "react";


export async function loader({ request}) {
    const url = new URL(request.url);
    const q = url.searchParams.get("q");
    const races = await getRaces(q);
    return {races, q};
}

import {toggleNav, removeNav} from "../sidebar"

export default function Races() {
    const {races, q} = useLoaderData();
    const navigation = useNavigation();
    const submit = useSubmit();

    const searching = navigation.location && new URLSearchParams(navigation.location.search).has("q");

    useEffect(() => {
        document.getElementById("q").value = q;
    }, [q]);

    return(
        <>
            <div id="sidebar" className="sidebar hidden">
            <a
                        className="closebtn"
                        onClick={() => toggleNav()}>×</a>
                <div>
                    <Form id="search-form" role="search">
                        <input
                            id="q"
                            className={searching ? "loading" : ""}
                            aria-label="Search races"
                            placeholder="Search races"
                            type="search"
                            name="q"
                            defaultValue={q}
                            onChange={(event) => {
                                const isFirstSearch = q == null;
                                submit(event.currentTarget.form, {replace: !isFirstSearch});
                            }}
                        />
                        <div
                            id="search-spinner"
                            aria-hidden
                            hidden={!searching}
                        />
                        <div
                            className="sr-only"
                            aria-live="polite"
                        ></div>
                    </Form>
        


                </div>

                    <nav id="sidebarScroll">
                        {races.length ? (
                            <>
                            {races.map((season) => (
                                <ul className= "sidebarSeason" key={season.season}>
                                    {season.season_display}

                                    {
                                        season.options.length ? (

                                            
                                            
                                            season.options.map((race) => (
                                                
                                                <li className="sidebarRace" key={race.date_ymd}>
                                    <NavLink
                                        to={race.date_ymd}
                                        className={({isActive, isPending}) => isActive ? "active" : isPending ? "pending" : ""}
                                        onClick={() => removeNav()}>
                                        {race.date_display ? (
                                            <>
                                            {race.date_display}
                                            </>
                                        ) : (
                                            <i>No Name</i>
                                        )}

                                        {/* Show extraNote */}
                                        {race.extraNote ? (
                                            <>
                                            <br></br>
                                            {race.extraNote}
                                            </>
                                            ):("")}
                                        {/* Show cancellation */}
                                        {race.cancelled_reason ? (
                                            <>
                                            <br></br>
                                            {/* {"Cancelled due to " + race.cancelled_reason} */}
                                            {`Cancelled (${race.cancelled_reason})`}
                                            </>
                                            ):("")}
    
    {/* {" "} */}
                                    </NavLink>
                                </li>
                                )
                            )) :(
                                <p><i>No matches</i></p> 
                            )
                        }
                                        </ul>
                            ))}
                        </>
                        ) : (
                            <p><i>No Races</i></p>
                            
                        )}
                    </nav>
                </div>
            <div
                className="contentScroll contentHasSidebar"
            
            >
                <Row className="rowBtnToggle">

                    <button
                    className="btnToggle"
                    onClick={() => toggleNav()}>
                        ☰ Show Races
                </button>
                        </Row>
                <Outlet />
            </div>
        
        </>
    )
}