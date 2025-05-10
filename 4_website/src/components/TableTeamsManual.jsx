import { DataTable } from 'primereact/datatable';
import { Column } from 'primereact/column';
import { Col } from 'react-bootstrap';
import { Link } from 'react-router-dom';

import { intersperse } from '../intersperse';

export default function TableTeamsManual({tabData}) {

    // debugger;

    
    
    return(

        <DataTable
            value={tabData}

              // sorting
        sortField="TimeTotalDisplay"
        sortOrder={1}
        >
            <Column
                header="Time"
                sortable
                field="TimeTotalDisplay"
            />

            <Column
                header="Members"
                field="teamID"
                body={(dat) => {

                    const tags = dat.list_name_display.map((e, i) => {
                        return(
                            <Link key={i} to={`/members/${dat.list_id_member[i]}`}>{e}</Link>
                        )
                    })
                    
                    return(intersperse(tags, ", ") )

                }}
            />


        </DataTable>
                
    )
}