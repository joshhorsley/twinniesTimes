import { DataTable } from 'primereact/datatable';
import { Column } from 'primereact/column';

import { Form } from 'react-router-dom';

import dataTotalRaces from "../data/totalRaces.json";
import dataTotalRacesColumns from "../data/totalRaces_columns.json";
import { Container, PopoverBody } from 'react-bootstrap';
import { Link } from 'react-router-dom';
import { useState } from 'react';

import { FilterMatchMode } from 'primereact/api';

// import { InputText } from 'primereact/inputtext';
// import { IconField } from 'primereact/iconfield';
// import { InputIcon } from 'primereact/inputicon';

// import {  } from 'react';

import PageTitle from "../components/PageTitle";



import {Popover, OverlayTrigger } from "react-bootstrap";


export default function TotalRaces() {
    const [filters, setFilters] = useState({
        global: {value: null, matchMode: FilterMatchMode.CONTAINS}
    })

    const [globalFilterValue, setGlobalFilterValue] = useState('');

    const onGlobalFilterChange = (e) => {
        const value = e.target.value;
        let _filters = { ...filters };

        _filters['global'].value = value;

        setFilters(_filters);
        setGlobalFilterValue(value);
    };

    // const clearFilter = () => {

    //     const value = "";
    //     let _filters = { ...filters };

    //     _filters['global'].value = value;

    //     setFilters(_filters);
    //     setGlobalFilterValue(value);

    // }

    const renderHeader = () => {
        return (
            <div>
                    {/* <InputText
                       spellCheck="false"
                       autoCorrect="off"
                           className='inputSearchTable'
                           value={globalFilterValue} onChange={onGlobalFilterChange} placeholder="Search by name" /> */}
                    <Form id="search-form" role = "search">

                        <input
                            id="qTab"
                            name="q"
                            type="search"
                            value={globalFilterValue}
                            onChange={onGlobalFilterChange}

                            // className={searching ? "loading" : ""}
                            spellCheck="false"
                            aria-label="Search by name"
                            placeholder='Search by name'

                        />
                          <div
                            className="sr-only"
                            aria-live="polite"
                        ></div>
                        </Form>
                    {/* <button onClick={() => clearFilter()}>Clear</button> */}

            </div>
        );
    };

    const header = renderHeader();


// example of sticky header
// https://codesandbox.io/p/sandbox/flamboyant-dawn-nvd7oc?file=%2Fsrc%2Fdemo%2FDataTableDemo.css%3A38%2C1-61%2C1


return(
<>
<PageTitle title = "Total Races"/>

<div className="contentScroll">


        
<Container>
        <h1>Total races as of {dataTotalRaces.dateUpdated}</h1>


<DataTable
    value={dataTotalRaces.totalData}
    // className='p-datatable-customers stickyTable'
    
    size="small"
    
    
    // for search
    filters={filters}
    filterDisplay="row"
    globalFilterFields={['name_display']}
    header={header}
    
    // sorting
    sortField="races_full"
    sortOrder={-1}
    
    stripedRows
    // showGridlines not working?
    // tableStyle={{ minWidth: '50rem' }}
    
    paginator
    // paginatorPosition="top"
    rows={25}
    rowsPerPageOptions={[5, 10, 25, 50]}
    
    // stateStorage="session"
    // stateKey="dt-state-total-races"
    
    scrollable // this is needed for frozen columns
    // scrollHeight="400px"
    >
        {/* Name */}
        <Column
            field="name_display"
            header="Name"
            
            body={dataTotalRaces => {
                return(
                    <Link to={`/members/${dataTotalRaces.id_member}`} >{dataTotalRaces.name_display}</Link>
                )
            }}
            
            sortable
            frozen
            style={{ minWidth: '100px' }}/>

        {dataTotalRacesColumns.map((col) => (
            
            
            
            <Column
            key={col.columnID}
            field={col.columnID}
            sortable
            style={{ minWidth: '100px', textAlign:"left"}}
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

    {/* <Column field="races_full" header="Sprint+" sortable/> */}
    {/* <Column field="total" header="All Races*" sortable/> */}

</DataTable>
</Container>

        </div>

            </>

)

}