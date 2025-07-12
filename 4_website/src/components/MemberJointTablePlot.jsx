import { SelectButton } from "primereact/selectbutton";
import { Row } from "react-bootstrap";
import { useEffect, useState } from "react";

import MemberPlot from "./MemberPlot";
import MemberTable from "./MemberTable";
import { TabView, TabPanel } from "primereact/tabview";

const dataOptionAll = { label: "All/Summary", value: "all" };

export default function MemberJointTablePlot({ plotData, tabData, raceType }) {
  const [dataOption, setDataOption] = useState("all");
  const [dataOptions, setDataOptions] = useState([dataOptionAll]);

  // race distance to display
  useEffect(() => {
    const raceTypeProcessed = raceType[0].map((e) => {
      return { value: e.value[0], label: e.label[0] };
    });
    setDataOptions([dataOptionAll, ...raceTypeProcessed]);
  }, [raceType]);

  // if switching person and they don't have currently selected distance then set to 'all'
  useEffect(() => {
    const haveOption =
      dataOptions.filter((e) => e.value == dataOption).length == 1;
    if (!haveOption) {
      setDataOption("all");
    }
  }, [dataOptions]);

  return (
    <>
      <Row>
        <div style={{ float: "left" }}>
          Distance
          <SelectButton
            allowEmpty={false}
            value={dataOption}
            options={dataOptions}
            optionValue="value"
            optionLabel="label"
            onChange={(e) => setDataOption(e.value)}
          />
        </div>
      </Row>
      <TabView renderActiveOnly={false}>
        <TabPanel header="Graph" leftIcon="pi pi-chart-bar mr-2">
          <p>Races plotted 2024/25 onwards</p>

          {plotData && (
            <MemberPlot plotData={plotData} dataOption={dataOption} />
          )}
        </TabPanel>
        <TabPanel header="Table" leftIcon="pi pi-table mr-2">
          <MemberTable tabData={tabData} dataOption={dataOption} />
        </TabPanel>
      </TabView>
    </>
  );
}
