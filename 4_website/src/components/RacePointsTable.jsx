import { DataTable } from "primereact/datatable";
import { Column } from "primereact/column";
import { ColumnGroup } from "primereact/columngroup";
import { Link } from "react-router-dom";

import { Row } from "react-bootstrap";

export default function RacePointsTable({ pointsTab }) {
  const headerGroup = (
    <ColumnGroup>
      <Row>
        <Column header="Name" frozen rowSpan={2} />
        <Column header="Awarded" colSpan={3} />
        <Column header="Total" colSpan={2} />
      </Row>

      <Row>
        <Column
          header="Participation"
          sortable
          field="points_participation_awarded"
        />
        <Column header="Handicap" sortable field="points_handicap_awarded" />
        <Column header="All" sortable field="points_all_awarded" />
        <Column header="Previous" sortable field="points_all_total_previous" />
        <Column header="Now" sortable field="points_all_total" />
      </Row>
    </ColumnGroup>
  );
  return (
    <>
      <Row>
        {pointsTab && (
          <DataTable
            value={pointsTab[0]}
            headerColumnGroup={headerGroup}
            sortField="points_all_awarded"
            sortOrder={-1}
          >
            <Column
              field="id_member"
              //   header="Name"
              //   sortable
              //   frozen
              body={(data) => {
                return (
                  <Link to={`/members/${data.id_member}`}>
                    {data.name_display}
                  </Link>
                );
              }}
            />
            <Column
              //   header="Participation"
              field="points_participation_awarded"
              //   sortable
            />
            <Column
              //   header="Handicap"
              field="points_handicap_awarded"
              body={(data) => {
                return (
                  <>
                    {data.points_handicap_awarded != 0
                      ? data.points_handicap_awarded
                      : ""}
                  </>
                );
              }}
              //   sortable
            />
            <Column
              // header="All"
              field="points_all_awarded"
              //   sortable
            />
            <Column
              field="points_all_total_previous"
              //   header="Previous"
              //   sortable
              body={(data) => {
                return (
                  data.points_all_total_previous && (
                    <>{`${data.points_all_total_previous} (${
                      data.rank_all_total_previousDisplay +
                      (data.rankIsEqual_previous ? " eq" : "")
                    })`}</>
                  )
                );
              }}
            />
            <Column
              field="points_all_total"
              //   header="Now"
              //   sortable
              body={(data) => {
                return (
                  <>{`${data.points_all_total} (${
                    data.rank_all_totalDisplay + (data.rankIsEqual ? " eq" : "")
                  })`}</>
                );
              }}
            />
          </DataTable>
        )}
      </Row>
    </>
  );
}
