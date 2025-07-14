import { DataTable } from "primereact/datatable";
import { Column } from "primereact/column";

import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { SelectButton } from "primereact/selectbutton";

import partsDefAll from "../data/partsDef.json";

export default function BestTimesTable({ tabData }) {
  const [partsDef, setPartsDef] = useState();
  const [nLaps, setNLaps] = useState(1);

  const [distance, setDistance] = useState("sprint");
  const [tabDataUse, setTabDataUse] = useState();

  // distance
  useEffect(() => {
    const haveDistance =
      tabData.distances.filter((e) => e.distanceID == distance).length == 1;

    if (!haveDistance) {
      const haveSprint =
        tabData.distances.filter((e) => e.distanceID == "sprint").length == 1;

      if (haveSprint) {
        setDistance("sprint");
      } else {
        setDistance(tabData.distances[0].distanceID);
      }
    }
  }, [tabData]);

  useEffect(() => {
    Object.hasOwn(tabData.data, distance) &&
      setTabDataUse(tabData.data[distance]);
  }, [tabData, distance]);

  useEffect(() => {
    distance && setPartsDef(partsDefAll.partsDef[distance]);
    distance && setNLaps(partsDefAll.nLaps[distance][0]);
  }, [tabData, distance]);

  return (
    <>
      <SelectButton
        allowEmpty={false}
        value={distance}
        options={tabData.distances}
        optionValue="distanceID"
        optionLabel="distanceDisplay"
        onChange={(e) => setDistance(e.value)}
      />
      <DataTable value={tabDataUse} sortField="TimeTotal" sortOrder={1}>
        <Column
          field="id_member"
          header="Name"
          sortable
          frozen
          body={(data) => {
            return (
              <Link to={`/members/${data.id_member}`}>{data.name_display}</Link>
            );
          }}
        />
        <Column field="TimeTotal" header="Total" sortable />
        {distance != "teams" && partsDef && (
          <Column field="Lap1" header={partsDef[0].partDisplay} sortable />
        )}
        {partsDef && nLaps > 1 && (
          <Column field="Lap2" header={partsDef[1].partDisplay} sortable />
        )}
        {partsDef && nLaps > 2 && (
          <Column field="Lap3" header={partsDef[2].partDisplay} sortable />
        )}
        {partsDef && nLaps > 3 && (
          <Column field="Lap4" header={partsDef[3].partDisplay} sortable />
        )}
        {partsDef && nLaps > 4 && (
          <Column field="Lap5" header={partsDef[4].partDisplay} sortable />
        )}
      </DataTable>
    </>
  );
}
