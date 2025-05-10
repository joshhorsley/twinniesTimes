import { DataTable } from 'primereact/datatable';
import { Column } from 'primereact/column';

import { Form } from 'react-router-dom';



import { Card, Container, PopoverBody } from 'react-bootstrap';
import { Link } from 'react-router-dom';
import { 
    useEffect,
    // useRef, 
    useState } from 'react';
    
    import { FilterMatchMode, 
        // FilterOperator 
    } from 'primereact/api';
    
    // import { Button } from 'primereact/inputtext';
    // import { InputText } from 'primereact/inputtext';
    // import { IconField } from 'primereact/iconfield';
    // import { InputIcon } from 'primereact/inputicon';
    
    import {  } from 'react';
    
    
    import {Popover, OverlayTrigger } from "react-bootstrap";
    

    import PageTitle from "../components/PageTitle";


// Data --------------------------------------------------------------------------------------------


import dataStartTimes from "../data/startTimes.json";
import dataTotalRacesColumns from "../data/startTimes_columns.json";
// import { Button } from 'bootstrap';

// const dataStartTimesUse = dataStartTimes.at(-1).starts
// debugger;

// console.log(dataStartTimes)
// console.log(dataStartTimes.tableStarts)
// console.log(dataStartTimes.tableStarts.map((member) => {console.log(member.changeHistory[0].length)}))

// Component --------------------------------------------------------------------------------------------


export default function StartTimes() {
    // location state
    const [tableStart, setTableStart] = useState({
        // start: document.getElementById("tableCommittee").offsetTop
        start: 173
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

    // filter state
    const [filters, setFilters] = useState({
        global: {value: null, matchMode: FilterMatchMode.CONTAINS}
    })

    const [globalFilterValue, setGlobalFilterValue] = useState('');



    // expansion state
    const [expandedRows, setExpandedRows] = useState(null);

      const collapseAll = () => {
        setExpandedRows(null);
    };


    // filtering
    const onGlobalFilterChange = (e) => {
        const value = e.target.value;
        let _filters = { ...filters };

        _filters['global'].value = value;

        setFilters(_filters);
        setGlobalFilterValue(value);
    };


    const renderHeader = () => {
        return (
            <div>


<Form id="search-form" role = "search">

<input
    id="qTab"
    name="q"
    type="search"
    value={globalFilterValue}
    onChange={onGlobalFilterChange}

    // className={searching ? "loading" : ""}
    spellCheck="false"
    aria-label="Search by name or chip"
    placeholder='Search by name or chip'

/>
  <div
    className="sr-only"
    aria-live="polite"
></div>


                        {/* <button
                            onClick={() => clearFilter()}
                            style={{ marginLeft: '2px' }}
                            >Clear</button> */}


                        <button onClick={() => collapseAll()}
                            style={{ marginLeft: '20px', marginTop: '10px' }}
                            >Collapse All</button>
                            </Form>
            </div>
        );
    };

    const header = renderHeader();


// example of sticky header
// https://codesandbox.io/p/sandbox/flamboyant-dawn-nvd7oc?file=%2Fsrc%2Fdemo%2FDataTableDemo.css%3A38%2C1-61%2C1


// row expansion functions --------------------------------------------------------------------------------------------

const allowExpansion = (rowData) => {
    // return rowData.changeHistory[0].length > 0;
    return rowData.hasChangeDisplay == true;
};


const rowExpansionTemplate = (data) => {

    return (
        <Card>

        <div className="p-3">
            <h5>Start time change history for {data.name_display}</h5>
            <DataTable value={data.changeHistory[0]}>
                <Column field="dateNextStartDisplay" header="Date" ></Column>
                <Column field="nextStartTime_display" header="Start Time" ></Column>
            </DataTable>
        </div>
        </Card>
    );
};

// return --------------------------------------------------------------------------------------------


return(
    <>
            <PageTitle title = "Start Times"/>


<div className="contentScroll">


        
<Container>
<h1>
          {dataStartTimes.dateNext ? (
              <>
              {'Sprint start times ' + dataStartTimes.dateNext}
            </>
          ) : (
              <i>No Date</i>
            )}{" "}
        </h1>


<DataTable
    id="tableStartTimes"
    // value={dataStartTimes[dataStartTimes.length-1].starts}
    value={dataStartTimes.tableStarts}
    // expandedRows={ {"pearce_clive": true}}
    expandedRows={expandedRows}
    onRowToggle={(e) => setExpandedRows(e.data)}
    rowExpansionTemplate={rowExpansionTemplate}
    
    size="small"
    
    dataKey="id_member"
    // className='p-datatable-customers stickyTable'
    
    // for search
    filters={filters}
    filterDisplay="row"
    // globalFilterFields={['name_display', 'chip']}
    globalFilterFields={['name_display', 'chipLatest']}
    header={header}
    
    // sort
    sortMode="multiple"
    multiSortMeta={[
        // {field:"nextStartTime_displayStatus", order: -1},
        {field:"chipLatest", order: 1}
        
    ]}
    
    stripedRows
    // showGridlines not working?
    // tableStyle={{ minWidth: '50rem' }}
    
    // paginator
    // paginatorPosition="top"
    // rows={25}
    // rowsPerPageOptions={[5, 10, 25, 50]}
    
    // stateStorage="session"
    // stateKey="dt-state-start-times"
    
    scrollable
    scrollHeight={`${windowDimensions.height - tableStart.start - 10}px`}
    
    // scrollHeight="400px"
    >
        {/* Name */}
        <Column
            field="name_display"
            header="Name"
            
            body={tableData => {
                return(
                    <Link to={`/members/${tableData.id_member}`} >{tableData.name_display}</Link>
                )
            }}
            
            sortable
            frozen
            style={{ maxWidth: '100px' }}/>

        {dataTotalRacesColumns.map((col) => ( 
            
            <Column
            key={col.columnID}
            field={col.columnID}
            sortable
            style={{ maxWidth: '100px', textAlign:"left"}}
            header={
                col.note ? (
                    <>
                        {
                            
                            
                            
                            <OverlayTrigger placement="top" overlay={<Popover><PopoverBody>{col.note}</PopoverBody></Popover>}>
                <span>
                {col.title + ' '}
                &#9432;
                </span>
                
                </OverlayTrigger>
        
    }
                    </>
                    ) : (
                        
                        col.title
                    )
                    
                    
                }
                />
            ))}

        {/* Expandable row */}
        <Column
            header = "History"
            field="hasChangeDisplay"
            sortable
            expander={allowExpansion}
            />


        {/* <Column header = "test"/> */}


 

</DataTable>
</Container>

        </div>
            </>
)

}