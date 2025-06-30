// modules

import Plot from "react-plotly.js";

import {
    useEffect,
    useState 
} from "react";

import { SelectButton } from "primereact/selectbutton";

import triCols from './../clubColours.json'

// plot constants

const  layoutBase = {
    barmode: "stack",

    legend: {
        x: 0, xanchor: 'left',
        y:1,
        yanchor: 'bottom',
        orientation: "h",
        itemclick: false,
        itemdoubleclick: false
    },

    dragmode: false,


    hovermode: "closest",
    hoverlabel: {
      font: {
        size: 20
      }
    },

    margin: {
        t: 60,b: 60, l: 0, r: 0
    },

    autosize: true

}

// data always show - for legend


const displayModeXOptions = [
    {label: "Unify start", value: "x0Common"},
    {label: "Real time", value: "x0Clock"}

]

const displayModeYOptions = [
    {label: "Total", value: "yTotal"},
    {label: "Finish", value: "yFinish"},

]

export default function RacePlot2({plotData}) {

    const [displayModeX, setDisplayModeX] = useState("x0Clock");
    const [displayModeY, setDisplayModeY] = useState("yTotal");
    const [distance, setDistance] = useState("sprint");
    const [category, setCategory] = useState("Handicap points");
    const [categoryOptions, setCategoryOptions] = useState();
    const [racers, setRacers] = useState(30);
    const [layoutCombined, setLayoutCombined] = useState();

    const [barData, setBarData] = useState(); // what is actually being displayed


    // distance
    useEffect(() =>{
        const haveDistance = plotData.distances.filter((e) => e.distanceID == distance).length == 1

        if(!haveDistance) {

            const haveSprint = plotData.distances.filter((e) => e.distanceID == "sprint").length == 1

            if(haveSprint) {
                setDistance("sprint")
            } else {
                setDistance(plotData.distances[0].distanceID)
            }
        }

    }, [plotData])

    // category
    useEffect(() => {

        if(plotData.categories) {
            
            const catDistanceOptions = plotData.categories.filter((e) => e.distanceID==distance)

            if(catDistanceOptions.length) {
                
                const haveCategory = catDistanceOptions.filter((e) => e.Category == category).length==1

                setCategoryOptions(catDistanceOptions)
                
                if(!haveCategory) {
                    setCategory(catDistanceOptions[0].Category)
                }
                
            }
        }

    }, [plotData, distance, category])

    // sort order default for points comp
    useEffect(() => {

        if(distance=="sprint" & category=="Handicap Points") {
            setDisplayModeY("yFinish")
            setDisplayModeX("x0Clock")
        } else {
            setDisplayModeY("yTotal")
            setDisplayModeX("x0Common")
        }


    }, [distance, category])



    useEffect(() => {

        const plotDataFiltered =  plotData.data
        .filter((e) => e.distanceID==distance)
        .filter((e) => e.Category==category)

        // bar data
        setBarData(
            
            plotDataFiltered.map((e) => {

            const customdataPrep = e.catData.dx.map((e2,i) => {
                const haveMultiple = Array.isArray(e.catData.name_display)

                if(haveMultiple) {
                    return({
                        lapDisplay: e.lapDisplay,
    
                        // insane workaround becaues of auto-unbox and .length works on character!
                        name_display: e.catData.name_display[i],
                        dx_hms: e.catData.dx_hms[i],
                        TimeTotal_hms: e.catData.TimeTotal_hms[i]
                    })
                    
                } else {

                    

                    return({
                        lapDisplay: e.lapDisplay,
    
                        // annoying workaround becaues of auto-unbox
                        name_display: e.catData.name_display,
                        dx_hms: e.catData.dx_hms,
                        TimeTotal_hms: e.catData.TimeTotal_hms
                    })

                }

            })


            return({
                type: "bar",
                orientation:'h',
                showlegend:false,

                base: e.catData[displayModeX],
                x: e.catData.dx,    
                y: e.catData[displayModeY],
                
                marker: {
                    color: triCols[e.lapType]
                },
                
                customdata: customdataPrep,
                hovertemplate: '%{customdata.name_display}<br>%{customdata.TimeTotal_hms}<br>%{customdata.lapDisplay}<br>%{customdata.dx_hms}<extra></extra>'
            })
        })
        )

        // name annotations
        const annotationsFiltered =  plotData.annotations
        .filter((e) => e.distanceID==distance)
        .filter((e) => e.Category==category)


        let annotationsPrep

            if(annotationsFiltered.length) {
                if(Object.hasOwn(annotationsFiltered[0], "annotations")) {

                    
                    
                    annotationsPrep = annotationsFiltered[0].annotations.name_display.map((e,i) => {

                        const annotationProps = annotationsFiltered[0].annotations.points_handicap_display.map((e, i) => {

                            if(annotationsFiltered[0].annotations.x0Clock[i]=="NA") {
                                return({text: " (Not timed)",})
                            }

                            return(e==0 ? (
                                {
                                    text: "",
                                    color: "black"}

                            ) : (
                                {
                                    text: " " + annotationsFiltered[0].annotations.timeDiff[i] + "s → " + e + "pts",
                                    color: "green"}))
                        })
                        
                        return({
                            text: annotationsFiltered[0].annotations.name_display[i] + annotationProps[i].text,
                            x: annotationsFiltered[0].annotations[displayModeX][i] + 90,
                            y: annotationsFiltered[0].annotations[displayModeY][i],

                            font: {size: "13",
                                color: annotationProps[i].color},

                             xanchor: "left",
                             yanchor: "middle",
                             showarrow: false

                        })
                        
                    })

               
             
                }
            }

         

        // layout x axis
                            
        const layoutFiltered = plotData.layoutAxes
        .filter((e) => e.distanceID==distance)
        .filter((e) => e.Category==category)

        let xaxisPrep

        if(layoutFiltered.length) {
            if(Object.hasOwn(layoutFiltered[0], "xaxis")) {

                
                xaxisPrep = {
                    tickvals: layoutFiltered[0].xaxis.tickvals,
                    ticktext: displayModeX=="x0Clock" ? layoutFiltered[0].xaxis.ticktext : layoutFiltered[0].xaxis.ticktextZero,
                    side: "top",
                }

            }

               // number of racers displayed
            if(Object.hasOwn(layoutFiltered[0], "racers")) {
                setRacers(layoutFiltered[0].racers)
            }
        }

        if(xaxisPrep && annotationsPrep ) {
            setLayoutCombined(
                {...layoutBase,
                    annotations: annotationsPrep,
                    xaxis: xaxisPrep,
                    yaxis: {range: [-1, plotDataFiltered[0].catData.name_display.length]}
                }
            )
        }

        // )




    }, [plotData, displayModeX, displayModeY, distance, category])




    return(
        <>
        Distance
        <SelectButton
        allowEmpty={false}
        value={distance}
        options={plotData.distances}
        optionValue="distanceID"
        optionLabel="distanceDisplay"
        onChange={(e) => setDistance(e.value)}
        />
        Category
        <SelectButton
        allowEmpty={false}
        value={category}
        options={categoryOptions}
        optionValue="Category"
        optionLabel="Category"
        onChange={(e) => setCategory(e.value)}
        />
        <details>
            <summary>Display options</summary>
        <span>
        <div  style={{float: "left", marginRight: "10px"}}>

        Time mode
         <SelectButton
                            allowEmpty={false}
                            value={displayModeX}
                            options={displayModeXOptions}
                            optionValue="value"
                            optionLabel="label"
                            onChange={(e) => setDisplayModeX(e.value)}
                            />
                                            </div>

        Sort by
         <SelectButton
                            allowEmpty={false}
                            value={displayModeY}
                            options={displayModeYOptions}
                            optionValue="value"
                            optionLabel="label"
                            onChange={(e) => setDisplayModeY(e.value)}
                            />
                            </span>
                            </details>

            <div style={{height: `${(racers+1)*30 + 100}px`}}>

                <Plot
                divId="plotly-plot"
                    style={{width: "100%", height: "100%"}}
                    data = {barData}
                    layout={layoutCombined}
                    config={{
                        responsive: true,
                        displayModeBar: false
                    }}
                    useResizeHandler={true}
                    />
            </div>

            {/* <DataTable /> */}
        </>
    )
}