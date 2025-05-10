// Library --------------------------------------------------------------------------

import Plot from "react-plotly.js";


// Data -----------------------------------------------------------------------------

import dataMain from "../data/points.json";

const frames = dataMain.plot.frames


  const data = [
    {
    type: "bar",
    orientation: "h",
    // x: [0, 0],
    // y: [-1, 1],

    ...frames[frames.length-1].data[0], // get values from 0th frame
},
{
    type: "bar",
    orientation: "h",
    ...frames[frames.length-1].data[1] // get values from 0th frame

  }

]


const newSliderSteps = frames.map((frame) => {

    return(
        {
            label: frame.name,
            method: "animate",
            args: [[frame.name], {
                mode: 'immediately',
                transition: {duration: 10000},
                frame: {duration: 10000}
            }]
            
        }
    )
} )




const layout = {

    // hovering
    hovermode: "closest",
    hoverlabel: {
        // bgcolor: 'white',

      font: {
        size: 20
      }
    },

    sliders: [
        {
          active: frames.length-1,
        //   activebgcolor: "red",
        //   bgcolor: "blue",
          steps: newSliderSteps,
          x: 0.5,
          len: 0.5,
          xanchor: "left",
          y: 1,
          yanchor: "bottom",
          pad: { t: 10, b: 40, l: 20, r: 20 },
          currentvalue: {
            prefix: "Viewing: ",
            font: {size: 20}
            // visible: false
          },
          transition: {
            duration: 5000,
            // easing: "cubic-in-out"
          }
        }
      ],

      updatemenus: [{
        type: "buttons",
        showactive: false,
        pad: { t: 10, b: 40, l: 20, r: 20 },
        x: 0.5,
        y: 1,
        yref: 'container',
        xanchor: "right",
        yanchor: "bottom",
        // direction: 'left',
        buttons: [{
            label: 'Play',
            method: 'animate',
            args: [null, {
                fromcurrent: true,
                frame: {redraw: false, duration: 10000},
                transition: {duration: 10000}
            }]
        },{
            label: "Pause",
            method: "animate",
            args: [[null],{
                mode: 'immediate',
                frame: {redraw: false, duration: 0}
            }]
        }]
      }],

      margin: {
        t: 0,b: 20, l: 40, r: 10
    },

    barmode: "stack",

    legend: {
        x: 0,
        y: 1.01,
        // yref: 'container',
        yanchor: 'bottom',
        orientation: 'v',
        itemclick: false,
        itemdoubleclick: false,

        font: {size: 15},
        itemsizing: "constant"
    },
    annotations: dataMain.plot.annotation,
    // annotations: [
    //     {
    //         x: 68,
    //         y: 4,
    //         xanchor: 'left',
    //         font: {
    //             size: 20
    //         },
    //         text: 'Greg Fisher'


    //     }
    // ],

    xaxis: {
        side: 'top',
        fixedrange: true
    },

    yaxis: {
        fixedrange: true,
        title: "Place",
        // range: dataMain.plot.plotRangeY

        ...dataMain.plot.yaxisAddIn
    }

    // yaxis: {
    //     range: [0,3]
    // }


    // xaxis2: {
    //     position: 0.9,
    //     range: [0,100],
    //     anchor: "free",
    //     overlaying: "x",
    //     side: "top"
    // },
    // xaxis2=dict(position = 0.9, title='Fahrenheit', anchor='free', overlaying='x', side='top', tickmode='array', 
    //     tickvals=np.linspace(32,212,26), range=[32,212], spikemode='across', spikesnap='cursor' ) 
    // yaxis: {automargin: true},
    // yaxis2: {
    //     automargin: true,
    //     anchor: 'free',
    //     overlay: "y",
    //     side: 'right'
    // }


    // barcornerradius: 15,


    // ...frames[frames.length-1].layout


}

// Component -----------------------------------------------------------------------------

export default function PointsPlot() {


    return(

        <Plot
        style={{width: "100%", height: "2000px"}}
        // style={{width: "100%", height: "2000px"}}
        data={data}
        layout={layout}
        frames={frames}
        config={{
            responsive: true,
            displayModeBar: false
        }}
        />
    )


}