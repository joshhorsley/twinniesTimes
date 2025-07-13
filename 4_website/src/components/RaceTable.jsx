import { Column } from "primereact/column";
import { DataTable } from "primereact/datatable";
import { useEffect, useState } from "react";
import { Link } from "react-router-dom";

import { PopoverBody, Popover, OverlayTrigger } from "react-bootstrap";

import partsDefAll from "../data/partsDef.json";

export default function RaceTable({ tabData, distance, category }) {
  const [partsDef, setPartsDef] = useState();
  const [nLaps, setNLaps] = useState(1);

  const [tabDataUse, setTabDataUse] = useState();

  useEffect(() => {
    Object.hasOwn(tabData, distance) &&
      Object.hasOwn(tabData[distance], category) &&
      setTabDataUse(tabData[distance][category]);
  });

  useEffect(() => {
    distance && setPartsDef(partsDefAll.partsDef[distance]);
    distance && setNLaps(partsDefAll.nLaps[distance][0]);
  }, [tabData, distance]);

  return (
    <>
      <DataTable
        value={tabDataUse}
        sortField="TimeTotalDisplay"
        sortOrder={1}
        stripedRows
        scrollable
      >
        <Column field="rankTotal" header="Rank" sortable />
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
        <Column field="TimeTotalDisplay" header="Time (total)" sortable />
        {tabDataUse && Object.hasOwn(tabDataUse[0], "timeDiff") && (
          <Column
            field="timeDiff"
            header={
              <OverlayTrigger
                placement="top"
                overlay={
                  <Popover>
                    <PopoverBody>
                      {"Negative value indicates beating handicap time"}
                    </PopoverBody>
                  </Popover>
                }
              >
                <span>
                  {"Handicap compare"}
                  <br></br>
                  {"(seconds)" + " "} &#9432;
                </span>
              </OverlayTrigger>
            }
            sortable
          />
        )}
        {tabDataUse &&
          Object.hasOwn(tabDataUse[0], "points_handicap_awarded") && (
            <Column
              field="points_handicap_awarded"
              header={
                <OverlayTrigger
                  placement="top"
                  overlay={
                    <Popover>
                      <PopoverBody>
                        {
                          "Handicap points not awarded in 'Non-handicapped' Category. See the Points tab on this page for a breakdown of all points awarded."
                        }
                      </PopoverBody>
                    </Popover>
                  }
                >
                  <span>
                    {"Handicap points"}
                    <br></br>
                    {"awarded" + " "} &#9432;
                  </span>
                </OverlayTrigger>
              }
              sortable
            />
          )}
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
