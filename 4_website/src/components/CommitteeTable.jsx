//  Packages --------------------------------------------------------

import { Link } from "react-router-dom";

import { useEffect,
    useState
 } from "react";

import { DataTable } from 'primereact/datatable';
import { Column } from 'primereact/column';


//  Data --------------------------------------------------------


import dataCommittee from "../data/committee.json"

import { intersperse } from "../intersperse";

//  Component --------------------------------------------------------


export default function CommitteeTable() {

    const [tableStart, setTableStart] = useState({
        // start: document.getElementById("tableCommittee").offsetTop
        start: 141
    });

    const [windowDimensions, setWindowDimensions] = useState({
            width: window.innerWidth,
            height: window.innerHeight,
  });

  useEffect(() => {

   const handleResize = () => {
      setWindowDimensions({
        width: window.innerWidth,
        height: window.innerHeight,
      });
    };

    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, []);



return(

    <DataTable
    id="tableCommittee"
    value={dataCommittee.tab.data}

        // sorting
        sortField="seasonDisplay"
        sortOrder={-1}

        scrollable
        scrollHeight={`${windowDimensions.height - tableStart.start - 10}px`}

>
    <Column
        field="seasonDisplay"
        header="Season"

        sortable
        frozen
    />


    {dataCommittee.tab.colDefs.map((col) => (

<Column
key = {col.columnID}
// field="season"
header={col.title}

body={e => {
    const tags = e[`${col.title}`].map((e2,i) => {
        return(
            <Link key={`${col.title}-${i}`} to={`/members/${e2.id_member}`} >{e2.name_display}</Link>
        )
    })

    return(intersperse(tags, ", ") )
}}
/>


    ))}


    

</DataTable>


)

}