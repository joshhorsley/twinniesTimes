import { SelectButton } from "primereact/selectbutton";
import { Row } from "react-bootstrap";
import { useEffect, useState } from "react";

import MemberPlot from "./MemberPlot";

const dataOptionAll = { label: "All", value: "all" };

export default function MemberJointTablePlot({ plotData, raceType }) {
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
      <MemberPlot plotData={plotData} dataOption={dataOption} />)
    </>
  );
}
