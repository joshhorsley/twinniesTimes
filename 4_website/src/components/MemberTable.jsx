import { Column } from "primereact/column";
import { DataTable } from "primereact/datatable";
import { Link } from "react-router-dom";

export default function MemberTable({ tabData, dataOption }) {
  return (
    <>
      <DataTable
        value={tabData.data[dataOption]}
        sortField="date_ymd"
        sortOrder={-1}
      >
        {/* All/summary columns */}
        <Column
          hidden={dataOption != "all"}
          field="distanceDisplay"
          header="Distance"
        />
        <Column
          hidden={dataOption != "all"}
          field="total"
          header="Total"
          sortable
        />
        {/* Distance detail columns */}

        <Column
          hidden={dataOption == "all"}
          field="date_ymd"
          header="Date"
          sortable
          body={(data) => {
            return (
              <Link to={`/races/${data.date_ymd}`}>{data.date_display}</Link>
            );
          }}
        />
        <Column
          hidden={dataOption == "all"}
          field="TimeTotalDisplay"
          header="Time (total)"
        />
      </DataTable>
    </>
  );
}
