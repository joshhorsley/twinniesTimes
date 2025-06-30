// Library --------------------------------------------------------------------------

import Plot from "react-plotly.js";

// Data -----------------------------------------------------------------------------

// import dataMain from "../data/points.json";
import { useEffect, useState } from "react";

// Component -----------------------------------------------------------------------------

export default function PointsPlotDynamic({ plotData }) {
  const [data, setData] = useState();
  const [newSliderSteps, setNewSliderSteps] = useState();
  const [layout, setLayout] = useState();

  // data
  useEffect(() => {
    setData([
      {
        type: "bar",
        orientation: "h",

        ...plotData.frames[plotData.frames.length - 1].data[0], // get values from 0th frame
      },
      {
        type: "bar",
        orientation: "h",
        ...plotData.frames[plotData.frames.length - 1].data[1], // get values from 0th frame
      },
    ]);
  }, [plotData]);

  // slider steps
  useEffect(() => {
    setNewSliderSteps(
      plotData.frames.map((frame) => {
        return {
          label: frame.name,
          method: "animate",
          args: [
            [frame.name],
            {
              mode: "immediately",
              transition: { duration: 10000 },
              frame: { duration: 10000 },
            },
          ],
        };
      })
    );
  }, [plotData]);

  // layout

  useEffect(() => {
    setLayout({
      // hovering
      hovermode: "closest",
      hoverlabel: {
        font: {
          size: 20,
        },
      },

      sliders: [
        {
          active: plotData.frames.length - 1,
          steps: newSliderSteps,
          x: 0.5,
          len: 0.5,
          xanchor: "left",
          y: 1,
          yanchor: "bottom",
          pad: { t: 10, b: 40, l: 20, r: 20 },
          currentvalue: {
            prefix: "Viewing: ",
            font: { size: 20 },
          },
          transition: {
            duration: 5000,
          },
        },
      ],

      updatemenus: [
        {
          type: "buttons",
          showactive: false,
          pad: { t: 10, b: 40, l: 20, r: 20 },
          x: 0.5,
          y: 1,
          yref: "container",
          xanchor: "right",
          yanchor: "bottom",
          buttons: [
            {
              label: "Play",
              method: "animate",
              args: [
                null,
                {
                  fromcurrent: true,
                  frame: { redraw: false, duration: 10000 },
                  transition: { duration: 10000 },
                },
              ],
            },
            {
              label: "Pause",
              method: "animate",
              args: [
                [null],
                {
                  mode: "immediate",
                  frame: { redraw: false, duration: 0 },
                },
              ],
            },
          ],
        },
      ],

      margin: {
        t: 0,
        b: 20,
        l: 40,
        r: 10,
      },

      barmode: "stack",

      legend: {
        x: 0,
        y: 1.01,
        yanchor: "bottom",
        orientation: "v",
        itemclick: false,
        itemdoubleclick: false,

        font: { size: 15 },
        itemsizing: "constant",
      },
      annotations: plotData.annotation,

      xaxis: {
        side: "top",
        fixedrange: true,
      },

      yaxis: {
        fixedrange: true,
        title: "Place",

        ...plotData.yaxisAddIn,
      },
    });
  }, [plotData, newSliderSteps]);

  // debugger;

  return (
    <Plot
      style={{ width: "100%", height: "2000px" }}
      data={data}
      layout={layout}
      frames={plotData.frames}
      config={{
        responsive: true,
        displayModeBar: false,
      }}
    />
  );
}
