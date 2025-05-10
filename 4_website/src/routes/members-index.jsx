import { Container } from "react-bootstrap"

// import { addNav } from "../sidebar"
// import { useEffect } from "react"

import PageTitle from "../components/PageTitle";


export default function MemberIndex() {

// useEffect(() => {

//     addNav()
// }, [])

    return(
        <>
        <PageTitle title = "Members"/>

        <Container>
            <p>
                Select current and former members and visitors from the sidebar.
            </p>
        </Container>
        </>
    )
}