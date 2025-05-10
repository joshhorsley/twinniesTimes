import { SelectButton } from "primereact/selectbutton";
import { useEffect, useState } from "react";
import { Row } from "react-bootstrap";
import Plot from "react-plotly.js";

import triCols from './../clubColours.json'

// data constant --------------------------------------------------------


const xaxisBase = {
    rangeslider: {
        thickness: 0.05,
        borderwidth: 1,
        y: 0,
        yanchor: "top"
    },

}

const layoutBase = {
    barmode: "stack",

    yaxis: {
        fixedrange: true,
        tickmode: "array",
        ticktext: ["0:15", "0:30","0:45","1:00","1:15","1:30","1:45","2:00","2:15","2:30"],
        tickvals: [900, 1800, 2700, 3600, 4500,5400,6300,7200, 8100, 9000],
        title: "Time (h:mm)"
        // dtick: 900
    },

    dragmode: "pan",

    margin: {
        t: 0,b: 20, l: 50, r: 20
    },

    legend: {
        x: 0, xanchor: 'left',
        y:1,
        yanchor: 'bottom',
        orientation: "h",
        itemclick: false,
        itemdoubleclick: false
    },

    hovermode: "closest",
    hoverlabel: {
      font: {
        size: 20
      }
    },
}

// data always show - for legend

const dataAlways = [ {
    customdata: {distance: "always"},

    name: "Swim",
    marker: {color: triCols.swim},
    legendrank: "3",

    type: 'bar',
    x: [null],
    y: [null],
    
  },
  {
    customdata: {distance: "always"},

    name: "Ride",
    marker: {color: triCols.ride},
    legendrank: "2",


    type: 'bar',
    x: [null],
    y: [null],
    
  },
  {
    customdata: {distance: "always"},

    name: "Run",
    marker: {color: triCols.run},
    legendrank: "1",

    type: 'bar',
    x: [null],
    y: [null]
  },
  {
    customdata: {distance: "always"},

    name: "Teams",
    marker: {color: triCols.teamsTotal},
    legendrank: "0",

    type: 'bar',
    x: [null],
    y: [null]
  }]

  const dataEmpty = [
    {
        customdata: {distance: "awlways"},
        name: "empty",
        type: 'bar',
        showlegend:false,
        x: [null],
        y: [null],
    }
  ]


// data variable --------------------------------------------------------


// const dataOptions = [
//     {label: "All", value: "all"},
//     {label: "Sprint", value: "sprint"}
// ]

const dataOptionAll =  {label: "All", value: "all"}


const xRangeOptions = [
    {label: "Recent", value: "recent"},
    {label: "2024/25", value: "2024-2025"},
    // {label: "2023/24", value: "2023-2024"}
]

const offSeasonBase = {
    type: "rect",
    xref: "x",
    yref: "paper",
    y0: 0,
    y1: 1,
    fillcolor: '#d3d3d3',
    opacity: 0.75,
    line: {
        width: 0
    },
    label: {
        text: "Off-season",
        font: {size: 50, color: "white"}
    }
}

const cancellationBase = {
    type: "rect",
    xref: "x",
    yref: "paper",
    y0: 0,
    y1: 1,
    fillcolor: 'black',
    opacity: 0.5,
    line: {
        width: 0
    },
    // label: {
    //     text: "Cancelled",
    //     textangle: 90,
    //     font: {size: 10, color: "white"}
    // }
}


export default function MemberPlot({plotData}) {
    const [dataOptions, setDataOptions] = useState([dataOptionAll])
    const [dataOption, setDataOption] = useState("all")
    const [dataMember, setDataMember] = useState(dataAlways)
    const [dataUse, setDataUse] = useState(dataAlways)
    const [plotRangeOption, setPlotRangeOption] = useState("recent")
    // const [plotRange, setPlotRange] = useState([xRanges.recent[0], xRanges.recent[1]]);
    const [plotRange, setPlotRange] = useState([plotData.season_ranges.recent[0], plotData.season_ranges.recent[1]]);
    const [layout, setLayout] = useState(layoutBase);
    const [shapesPlot, setShapesPlot] = useState(null);


    // update shapes
    useEffect(() => {
        const shapeOutOffseason = plotData.shapesOffseason[0].map((e) => {
            return({
                x0: e.date_offSeasonStartDisplay,
                x1: e.date_offSeasonEndDisplay,

                ...offSeasonBase
            })
        })

        // console.log(shapeOutOffseason)

        const shapeOutCancellation = plotData.shapesCancelled[0].map((e) => {
            return({
                x0: e.date_startDisplay,
                x1: e.date_endDisplay,

                label: {
                    text: "No race: " + e.cancelled_reason,
                    textangle: 90,
                    font: {size: 10, color: "white"}
                },

                ...cancellationBase
            })
        })
        setShapesPlot([...shapeOutOffseason, ...shapeOutCancellation])

    }, [plotData])


    // update layout
    useEffect(() => {
        setLayout({
            ...layoutBase,

            shapes: shapesPlot,

            xaxis: {
                tick0: "2024-09-28",
                dtick: 7 * 24 * 3600000,
                range: plotRange,
                ...xaxisBase
            }
        })
    }, [plotRange, shapesPlot])


    // range changes
    useEffect(() => {
        if(plotRangeOption != "other") {
            // setPlotRange([xRanges[plotRangeOption][0], xRanges[plotRangeOption][1]])
            setPlotRange([plotData.season_ranges[plotRangeOption][0], plotData.season_ranges[plotRangeOption][1]])
        }
    },[plotData, plotRangeOption])

    function onClickRange(e) {
        e.value ? setPlotRangeOption(e.value) : null
    }

    function onRelayout(e) {
        setPlotRangeOption("other")
        e["xaxis.range[0]"] ? setPlotRange([e["xaxis.range[0]"], e["xaxis.range[1]"]]) : null
    }


    // update data displayed

    // update race type options for for person + 'all' option
    // initial json export isn't auto-unboxed to avoid other problems, so map to get first element of redundant arrays
    useEffect(() => {
        const raceTypeProcessed = plotData.raceType[0].map((e) => {return({value: e.value[0], label: e.label[0]})})
        setDataOptions([dataOptionAll, ...raceTypeProcessed])
    }, [plotData])


    // if switching person and they don't have currently selected distance then set to 'all'
    useEffect(() => {
        const haveOption = dataOptions.filter((e) => e.value==dataOption).length==1
        if(!haveOption) {
            setDataOption("all")
        }

    }, [dataOptions])



    // update data based on person
    useEffect(() => {

        if(!plotData.barData.length & !plotData.barDataManual.length & !plotData.marshalling.length) {
            setDataMember(dataEmpty)
        } else {
            let data2 = [];
            let data3 = [];
            let dataMarshalling = [];


            // timed results
            if(plotData.barData.length) {

                data2 = plotData.barData.map((e) => {
                    
                    const textLast = e.isLastLap[0] ? e.distanceDisplay[0] : null
                    const customdataPrep = e.x.map((e2, i) => {
                        return({
                            distance: e.distanceID[0],
                            dateNice: e.dateNice[i],
                            partDisplay : e.partDisplay[0],
                            TimeTotal: e.TimeTotal[i],
                            lapLength: e.lapLength[i]
                        })
                    })
                    
                    const hovertemplate = e.partDisplay[0]!="teamsTotal" ? (
                        '%{customdata.dateNice}<br><b>%{data.name}</b><br>%{customdata.TimeTotal}<br><b>%{customdata.partDisplay}</b><br>%{customdata.lapLength}<extra></extra>'
                    ) : (
                        '%{customdata.dateNice}<br><b>%{data.name}</b><br>%{customdata.TimeTotal}<br><extra></extra>'
                    )
                    
                    return({
                        showlegend:false,
                        type: 'bar',
                        width: 518400000,
                        
                        customdata: customdataPrep,
                        
                        name: e.distanceDisplay[0],
                        x: e.x,
                        y: e.y,
                        base: e.base,
                        text: textLast,
                        marker: {color: triCols[e.part[0]]},
                        hovertemplate: hovertemplate
                    })
                    
                })
            }

            //untimed results
            if(plotData.barDataManual.length) {

                data3 = plotData.barDataManual.map((e) => {

                    const customdataPrep = e.x.map((e2, i) => {
                        return({
                            distance: e.distanceID[0],
                            dateNice: e.dateNice[i],
                        })
                    })

                    const baseZero = e.x.map((e,i) => {return(0)})
                    const yDefault = e.x.map((e,i) => {return(5400)})

                    return({
                        showlegend:false,
                        type: 'bar',
                        width: 518400000,

                        customdata: customdataPrep,

                        name: e.distanceDisplay[0], 
                        x: e.x,
                        y: yDefault,
                        base: baseZero,
                        text: `${e.distanceDisplay[0]} (Not timed)`,
                        // textposition: "outside",
                        marker: {color: "white",
                            line: {
                                color: "black",
                                width: 0.1
                            }
                        },
                        hovertemplate: '%{customdata.dateNice}<br><b>%{data.name}</b><br>Not timed<br><extra></extra>'
                    })
                })

            }

        // update marshalling
        if(plotData.marshalling.length) {
            
            dataMarshalling = plotData.marshalling.map((e) => {

                const customdataPrep = e.x.map((e2, i) => {
                    return({
                        distance: "other"
                    })
                })

                const baseZero = e.x.map((e,i) => {return(0)})
                const textUse = e.x.map((e,i) => {return("Marshalling")})

                return({
                    showlegend:false,
                    type: 'bar',
                    width: 518400000,

                    customdata: customdataPrep,

                    name: "Marshalling",
                    x: e.x,
                    y: baseZero,
                    base: baseZero,
                    text: textUse,
                    textposition: "outside",
                    textangle: 90,
                    textfont: {size: 30}


                })
            })
        }
     
        setDataMember([...data2, ...data3, ...dataMarshalling])

        }


    }, [plotData])


    // update what is displayed as long as there is something to display
    useEffect(() => {

        if(dataOption == "all")  {
            setDataUse([...dataMember, ...dataAlways])
        } else {
            const dataSubset = dataMember.filter((e) => e.customdata[0].distance==dataOption)

            if(dataSubset.length) {
                setDataUse([...dataSubset, ...dataAlways])
            }
    }
        
    }, [dataMember, dataOption])


// component ------------------------------------------------------------------------


    return(
        <>
        <Row>

            <span>
                <div  style={{float: "left", marginRight: "10px"}}>

                    Jump to period
                    <SelectButton
                    // style={{float: "bottom"}}
                    allowEmpty={false}
                    value={plotRangeOption}
                    options={xRangeOptions}
                    optionValue="value"
                    optionLabel="label"
                    onChange={(e) => onClickRange(e)}
                    />
                    
                </div>
            

                <div style={{float: "left"}}>

                    Race types
                    <SelectButton
                        // style={{float: "left"}}
                        
                        allowEmpty={false}
                        value={dataOption}
                        options={dataOptions}
                        optionValue="value"
                        optionLabel="label"
                        onChange={(e) => setDataOption(e.value)}
                    />
        
                </div>
            </span>
                    </Row>



            <Plot
            style={{width: "100%", height: "500px"}}
            
            data={dataUse}
            layout={layout}
            // onRelayout={(e) => console.log(e["xaxis.range[1]"])}
            onRelayout={(e) => onRelayout(e)}
            config={{
                responsive: true,
                displayModeBar: false,
                doubleClick: false

            }}
            />
        </>
    )
}