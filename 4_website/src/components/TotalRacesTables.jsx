import { DataTable } from "primereact/datatable";
import { Column } from "primereact/column";

import { Form } from "react-router-dom";

import dataTotalRaces from "../data/totalRaces.json";
import { PopoverBody, Popover, OverlayTrigger } from "react-bootstrap";
import { Link } from "react-router-dom";
import { useState } from "react";

import { FilterMatchMode } from "primereact/api";

export default function TotalRacesTable({ tabDataList }) {
  const [filters, setFilters] = useState({
    global: { value: null, matchMode: FilterMatchMode.CONTAINS },
  });

  const [globalFilterValue, setGlobalFilterValue] = useState("");

  const onGlobalFilterChange = (e) => {
    const value = e.target.value;
    let _filters = { ...filters };

    _filters["global"].value = value;

    setFilters(_filters);
    setGlobalFilterValue(value);
  };

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
            spellCheck="false"
            aria-label="Search by name"
            placeholder="Search by name"
          />
          <div className="sr-only" aria-live="polite"></div>
        </Form>
      </div>
    );
  };

  const header = renderHeader();

  return (
    <DataTable
      value={dataTotalRaces.totalData}
      size="small"
      // for search
      filters={filters}
      filterDisplay="row"
      globalFilterFields={["name_display"]}
      header={header}
      // sorting
      sortField="races_full"
      sortOrder={-1}
      stripedRows
      paginator
      rows={25}
      rowsPerPageOptions={[5, 10, 25, 50]}
      scrollable
    >
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

      {dataTotalRaces.colsUse.map((col) => (
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
    </DataTable>
  );
}
