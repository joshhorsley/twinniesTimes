// Packages ------------------------------------------------------


import { useEffect } from "react";
import { useLocation } from "react-router-dom";


// Component ------------------------------------------------------


export default function PageTitle({title}) {
    const location = useLocation();

    useEffect(() => {
        document.title = title ? title + " | Twinnies Times": "Twinnies Times";
    }, [location, title])

    return null;
}
