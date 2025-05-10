// Library --------------------------------------------------------------------------

import Plot from "react-plotly.js";
import { useEffect, useState } from "react";


// Component -----------------------------------------------------------------------------


export default function PlotStandard({plotPrep}) {

    const [layout, setLayout] = useState();

    useEffect(() => {

        setLayout(
            {

                hovermode: "closest",
                hoverlabel: {
            
                  font: {
                    size: 20
                  }
                },
                legend: {
                    x : 0.5,
                    y: 1,
                    yanchor: "bottom",
                    xanchor: "center",
                    orientation: "h",
                    // itemclick: false,
                    // itemdoubleclick: false
                },
            
                margin: {
                    t: 40,b: 40, l: 40, r: 0
                },
            
                yaxis: {
                    fixedrange: true,
                    autorange: false,
                    
                    ...plotPrep.yaxisAddIn
                },
                xaxis: {
                    fixedrange: true,
                    autorange: false,
            
                    ...plotPrep.xaxisAddIn
                }
            }
        )



    }, [])




    return(

        <Plot
        style={{width: "100%"}}
        // style={{width: "100%", height: "2000px"}}
        data={plotPrep.data}
        layout={layout}
        // frames={frames}
        config={{
            responsive: true,
            displayModeBar: false
        }}
        />
    )


}