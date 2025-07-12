import { Column } from "primereact/column";
import { DataTable } from "primereact/datatable";
import { useEffect, useState } from "react";
import { Link } from "react-router-dom";

export default function MemberTable({ tabData, dataOption }) {
  const [partsDef, setPartsDef] = useState();
  const [nLaps, setNLaps] = useState(1);

  useEffect(() => {
    dataOption != "all" &&
      setPartsDef(tabData.list_partsDef[0][0].partsDef[dataOption]);
    dataOption != "all" &&
      setNLaps(tabData.list_partsDef[0][0].nLaps[dataOption][0]);
  }, [tabData, dataOption]);

  // console.log(tabData.list_partsDef[0][0].partsDef);
  console.log(partsDef);
  console.log(nLaps);
  return (
    <>
      {dataOption == "all" && <p>Distance totals for 2018/19 onwards</p>}
      {dataOption != "all" && <p>Races 2024/25 onwards</p>}
      <DataTable
        value={tabData.data[dataOption]}
        sortField="date_ymd"
        sortOrder={-1}
        stripedRows
        scrollable
      >
        {/* All/summary columns */}
        {dataOption == "all" && (
          <Column field="distanceDisplay" header="Distance" />
        )}
        {dataOption == "all" && (
          <Column field="total" header="Total" sortable />
        )}
        {/* Distance detail columns */}
        {dataOption != "all" && (
          <Column
            field="date_ymd"
            header="Date"
            sortable
            frozen
            body={(data) => {
              return (
                <Link to={`/races/${data.date_ymd}`}>{data.date_display}</Link>
              );
            }}
          />
        )}
        {dataOption != "all" && (
          <Column field="TimeTotalDisplay" header="Time (total)" sortable />
        )}
        {dataOption != "all" && dataOption != "teams" && partsDef && (
          <Column
            hidden={dataOption == "all" || dataOption == "teams"}
            field="Lap1"
            header={partsDef[0].partDisplay}
            sortable
          />
        )}
        {dataOption != "all" && partsDef && nLaps > 1 && (
          <Column field="Lap2" header={partsDef[1].partDisplay} sortable />
        )}
        {dataOption != "all" && partsDef && nLaps > 2 && (
          <Column field="Lap2" header={partsDef[2].partDisplay} sortable />
        )}
        {dataOption != "all" && partsDef && nLaps > 3 && (
          <Column field="Lap3" header={partsDef[3].partDisplay} sortable />
        )}
        {dataOption != "all" && partsDef && nLaps > 4 && (
          <Column field="Lap4" header={partsDef[4].partDisplay} sortable />
        )}
        {dataOption != "all" && partsDef && nLaps > 5 && (
          <Column field="Lap5" header={partsDef[5].partDisplay} sortable />
        )}
      </DataTable>
    </>
  );
}
