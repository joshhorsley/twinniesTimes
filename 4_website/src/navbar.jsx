import {
  Nav,
  Navbar,
  // NavbarCollapse,
  // NavItem,
  // Container
} from "react-bootstrap";
import {
  NavLink,
  // Link,
  useLocation,
  useNavigate,
} from "react-router-dom";

// import { ListGroup } from 'react-bootstrap';
// import LinkContainer from 'react-router-bootstrap'

import pathLogo from "./img/logo.png";

// How to fix changing navigation outside of header and not updating active status?
// https://github.com/react-bootstrap/react-router-bootstrap/issues/242

// NavLink active status works but collapse menu doesn't retract on mobile after selection
// hack status update by making Nav.Link dependant on pathname

// export default function AppNav({toggleTheme}) {
export default function Header() {
  const navigate = useNavigate();
  const { pathname } = useLocation(); // previously imported from 'react-router-dom'

  return (
    <Navbar
      collapseOnSelect
      sticky="top"
      id="navbar"
      expand="lg"
      className="bg-body-tertiary"
    >
      {/*<Navbar collapseOnSelect fixed="top" id="navbar" expand="lg" className="bg-body-tertiary"> */}
      {/* <Container> */}
      {/* <Nav className="me-auto"> */}
      {/* <ListGroup key={pathname}><ListGroup/> */}

      {/* <Nav.Link eventKey="1" as={Link} to="/"> */}
      <Navbar.Brand onClick={() => navigate("/")} className="navbarBranding">
        <img src={pathLogo} height="35px" /> Twinnies Times
      </Navbar.Brand>

      <Navbar.Toggle aria-controls="basic-navbar-nav" />
      <Navbar.Collapse id="basic-navbar-nav">
        <Nav activeKey={pathname} className="me-auto">
          {/* <Nav.Link eventKey="/" as={Link} to="/">Home</Nav.Link> */}
          <Nav.Link eventKey="/start-times" as={NavLink} to="/start-times">
            Start Times
          </Nav.Link>
          <Nav.Link eventKey="/points" as={NavLink} to="/points">
            Points
          </Nav.Link>
          <Nav.Link eventKey="/total-races" as={NavLink} to="/total-races">
            Total Races
          </Nav.Link>
          <Nav.Link eventKey="/races" as={NavLink} to="/races">
            Races
          </Nav.Link>
          <Nav.Link eventKey="/members" as={NavLink} to="/members">
            Members
          </Nav.Link>
          <Nav.Link eventKey="/committee" as={NavLink} to="/committee">
            Committee
          </Nav.Link>

          {/* <NavLink to="/start-times">Start Times</NavLink> */}
          {/* <NavLink  to="/">Home</NavLink>
            <NavLink  to="/total-races">Total Races</NavLink>
            <NavLink  to="/members">Members</NavLink>
            <NavLink  to="/races">Races</NavLink> */}
        </Nav>
        {/* <Nav>
            <Nav.Link onClick={toggleTheme}>Toggle Theme</Nav.Link>
            
            </Nav> */}
      </Navbar.Collapse>
      {/* </ListGroup> */}
      {/* </Container> */}
    </Navbar>
  );
}
