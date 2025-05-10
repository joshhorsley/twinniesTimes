
import { Card, Popover, OverlayTrigger } from "react-bootstrap";


export default function CardChange({title, value, change, previous, info}) {

    const popover = (
        <Popover id="popover-basic">
          <Popover.Body>{info ? info: ""}</Popover.Body>
        </Popover>
      );


    return(
        <Card className="cardStats">
            <Card.Body>
            <OverlayTrigger placement="top" overlay={popover}>
            <Card.Title>
              {title + ' ' } 
              &#9432;
              </Card.Title>
              </OverlayTrigger>

                {value ? <p>
                    <span style={{fontSize:'3em'}}>{value + " "}</span>
                    <span className={change < 0 ? "down" : "up"}>{change}</span>
                </p> 
                : ""
                }

                {previous ? <p>Previous: {previous}</p>: ""}

            </Card.Body>
        </Card>
    )

}