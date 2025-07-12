import { SelectButton } from "primereact/selectbutton";
import { Row } from "react-bootstrap";
import { useEffect, useState } from "react";

import { TabView, TabPanel } from "primereact/tabview";

import RacePlot2 from "./RacePlot2";
import RaceTable from "./RaceTable";

export default function RaceJointTablePlot({ plotData, tabData }) {
  const [distance, setDistance] = useState("sprint");
  const [category, setCategory] = useState("Handicap points");
  const [categoryOptions, setCategoryOptions] = useState();

  // distance
  useEffect(() => {
    const haveDistance =
      plotData.distances.filter((e) => e.distanceID == distance).length == 1;

    if (!haveDistance) {
      const haveSprint =
        plotData.distances.filter((e) => e.distanceID == "sprint").length == 1;

      if (haveSprint) {
        setDistance("sprint");
      } else {
        setDistance(plotData.distances[0].distanceID);
      }
    }
  }, [plotData]);

  // category
  useEffect(() => {
    if (plotData.categories) {
      const catDistanceOptions = plotData.categories.filter(
        (e) => e.distanceID == distance
      );

      if (catDistanceOptions.length) {
        const haveCategory =
          catDistanceOptions.filter((e) => e.Category == category).length == 1;

        setCategoryOptions(catDistanceOptions);

        if (!haveCategory) {
          setCategory(catDistanceOptions[0].Category);
        }
      }
    }
  }, [plotData, distance, category]);

  return (
    <>
      <Row>
        <div style={{ float: "left" }}>
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
        </div>
      </Row>
      <TabView renderActiveOnly={false}>
        <TabPanel header="Graph" leftIcon="pi pi-chart-bar mr-2">
          {plotData && (
            <RacePlot2
              plotData={plotData}
              distance={distance}
              category={category}
            />
          )}
        </TabPanel>
        <TabPanel header="Table" leftIcon="pi pi-table mr-2">
          <RaceTable
            tabData={tabData}
            distance={distance}
            category={category}
          />
        </TabPanel>
      </TabView>
    </>
  );
}
