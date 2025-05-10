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

import { getMembers } from "../members";
import { useEffect } from "react";


export async function loader({ request}) {
    const url = new URL(request.url);
    const q = url.searchParams.get("q");
    const members = await getMembers(q);
    return {members, q};
}


import {toggleNav, removeNav} from "../sidebar"

export default function Members() {
    const {members, q} = useLoaderData();
    const navigation = useNavigation();
    const submit = useSubmit();

    const searching = navigation.location && new URLSearchParams(navigation.location.search).has("q");

    useEffect(() => {
        document.getElementById("q").value = q;
    }, [q]);

    return(
        <>
            <div id="sidebar" className="sidebar hidden">
            {/* <div className="sidebar hidden"> */}
            <a
                        className="closebtn"
                        onClick={() => toggleNav()}>×</a>
                <div>
                    <Form id="search-form" role="search">
                        <input
                            spellCheck="false"
                            id="q"
                            className={searching ? "loading" : ""}
                            aria-label="Search members"
                            placeholder="Search members"
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
                        {members.length ? (

                            <>
                            {members.map((memberRecent, i) => (


                                
                                
                                <ul
                                    className="sidebarSeason"
                                    key = {memberRecent.memberRecentCat}
                                >
                                    {memberRecent.memberRecentCat}
                                    

                                {
                                    memberRecent.members.length ? (

                                        memberRecent.members.map((member) => (
                                            
                                            <li key={member.id_member} className="sidebarRace">
                                    <NavLink
                                        to={member.id_member}
                                        className={({isActive, isPending}) => isActive ? "active" : isPending ? "pending" : ""}
                                        onClick={() => removeNav()}>
                                        {member.name_display  ? (
                                            <>
                                            {member.name_display}
                                            </>
                                        ) : (
                                            <i>No Name</i>
                                        )}{" "}
                                    </NavLink>

                                    </li>

) 
)
) : (
    <p><i>No matches</i></p>
)
}
</ul>
))}
                        </>
                        ) 
                        : (
                        <p><i>No Members</i></p>
                    )
                        }

                    {/* } */}


                    </nav>
                        </div>
            <div
                className="contentScroll contentHasSidebar"
                // className={navigation.state === "loading" ? "loading" : ""}
            
            >
                <Row className="rowBtnToggle">

                    <button
                    className="btnToggle"
                    onClick={() => toggleNav()}>
                        ☰ Show Members
                </button>
                        </Row>

                <Outlet />
            </div>
        
        </>
    )
}