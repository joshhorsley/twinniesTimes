import { Card, Popover, OverlayTrigger } from "react-bootstrap";

export default function CardStats({children, title, info, value, valueText}) {

    const popover = (
      <Popover id="popover-basic">
        <Popover.Body>{info}</Popover.Body>
      </Popover>
    );
  
      return (
        <Card className="cardStats"
        
        // style={{ width: '15rem', height: '12rem' }}
        >
          <Card.Body>
            {info ?

              <OverlayTrigger placement="top" overlay={popover}>
            <Card.Title>
              {title + ' ' } 
              {/* <span> */}
              &#9432;
              {/* </span> */}
              </Card.Title>
              </OverlayTrigger>
              :
              <Card.Title>{title}</Card.Title>
          }
  
          
     
            {/* <Card.Subtitle className="mb-2 text-muted">Card Subtitle</Card.Subtitle> */}
            {/* <Card.Text> */}
              <p>
                <span style={{fontSize:'3em'}}>{value}</span>
                {valueText ? valueText : ""}
              </p>
              {children}
            {/* </Card.Text> */}
            {/* <Card.Link href="#">Card Link</Card.Link> */}
            {/* <Card.Link href="#">Another Link</Card.Link> */}
          </Card.Body>
        </Card>
      );
    }