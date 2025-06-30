//  Packages --------------------------------------------------------

import { DataTable } from "primereact/datatable";
import { Column } from "primereact/column";

import { Form } from "react-router-dom";

import { FilterMatchMode } from "primereact/api";
// import { InputText } from 'primereact/inputtext';

import { PopoverBody } from "react-bootstrap";
import { Link } from "react-router-dom";
import { useState } from "react";

import { Card, Popover, OverlayTrigger } from "react-bootstrap";

// import { IconField } from 'primereact/iconfield';
// import { InputIcon } from 'primereact/inputicon';

//  Data --------------------------------------------------------

// import dataMain from "../data/points.json";
import data_cols from "../data/points_columns.json";

//  Component --------------------------------------------------------

export default function PointsTableDynamic({ tableData }) {
  // filter state
  const [filters, setFilters] = useState({
    global: { value: null, matchMode: FilterMatchMode.CONTAINS },
  });

  const [globalFilterValue, setGlobalFilterValue] = useState("");

  // expansion state
  const [expandedRows, setExpandedRows] = useState(null);

  const collapseAll = () => {
    setExpandedRows(null);
  };

  // filtering
  const onGlobalFilterChange = (e) => {
    const value = e.target.value;
    let _filters = { ...filters };

    _filters["global"].value = value;

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
        <Form id="search-form" role="search">
          <input
            id="qTab"
            name="q"
            type="search"
            value={globalFilterValue}
            onChange={onGlobalFilterChange}
            // className={searching ? "loading" : ""}
            spellCheck="false"
            aria-label="Search by name"
            placeholder="Search by name"
          />
          <div className="sr-only" aria-live="polite"></div>

          <button
            onClick={() => collapseAll()}
            style={{ marginLeft: "20px", marginTop: "10px" }}
          >
            Collapse All
          </button>
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
      <Card className="cardRowExpansion">
        <div className="p-3">
          <h5>Points History for {data.name_display}</h5>
          <DataTable value={data.pointsHistory[0]}>
            <Column
              field="dateDisplay"
              header="Date"
              body={(data) => {
                return (
                  <Link to={`/races/${data.date_ymd}`}>{data.dateDisplay}</Link>
                );
              }}
            />

            <Column
              field="points_participation_awarded"
              header="Participation Awarded"
            ></Column>
            <Column
              field="points_handicap_awarded"
              header="Handicap Awarded"
            ></Column>
            <Column field="points_all_total" header="Running Total"></Column>
          </DataTable>
        </div>
      </Card>
    );
  };

  // Component

  return (
    <DataTable
      value={tableData}
      // className='p-datatable-customers stickyTable'

      expandedRows={expandedRows}
      onRowToggle={(e) => setExpandedRows(e.data)}
      rowExpansionTemplate={rowExpansionTemplate}
      size="small"
      // for search
      filters={filters}
      filterDisplay="row"
      globalFilterFields={["name_display"]}
      header={header}
      // sorting
      sortField="rank_all_total"
      sortOrder={1}
      stripedRows
      // showGridlines not working?
      // tableStyle={{ minWidth: '50rem' }}

      // paginator
      // paginatorPosition="top"
      // rows={25}
      // rowsPerPageOptions={[5, 10, 25, 50]}

      // stateStorage="session"
      // stateKey="dt-state-total-races"

      scrollable
      // scrollHeight="400px"
    >
      <Column
        field="rank_all_total"
        sortable
        header="Place"
        body={(dataTable) => {
          return dataTable.rankIsEqual ? (
            <>{dataTable.rank_all_total + " (eq)"}</>
          ) : (
            <>{dataTable.rank_all_total}</>
          );
        }}
        // frozen
      />

      {/* Name */}
      <Column
        field="name_display"
        header="Name"
        body={(dataTotalRaces) => {
          return (
            <Link to={`/members/${dataTotalRaces.id_member}`}>
              {dataTotalRaces.name_display}
            </Link>
          );
        }}
        sortable
        frozen
        style={{ minWidth: "100px" }}
      />

      {data_cols.map((col) => (
        <Column
          key={col.columnID}
          field={col.columnID}
          sortable
          style={{ minWidth: "100px", textAlign: "left" }}
          header={
            col.note ? (
              <>
                {
                  <OverlayTrigger
                    placement="top"
                    overlay={
                      <Popover>
                        <PopoverBody>{col.note}</PopoverBody>
                      </Popover>
                    }
                  >
                    <span>
                      {col.title + " "}
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
        header="History"
        field="id_member"
        sortable
        expander={allowExpansion}
      />
    </DataTable>
  );
}
