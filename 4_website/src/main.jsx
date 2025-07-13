// import modules ------------------------------------------------

import { StrictMode } from "react";
import { createRoot } from "react-dom/client";

import {
  createBrowserRouter,
  RouterProvider,
  createRoutesFromElements,
  Route,
  Outlet,
  Navigate,
  // NavLink
} from "react-router-dom";

// import styles ------------------------------------------------

// bootstrap
import "bootstrap/dist/css/bootstrap.min.css";

// custom
import "./index.css";

// prime
import "primeicons/primeicons.css"; // needed for tab icons used on Points
// import 'primeflex/primeflex.css'; // this has a .hidden class that hides sidebars

import "primereact/resources/primereact.css";
import "primereact/resources/themes/lara-light-indigo/theme.css";

// import components ------------------------------------------------

import ErrorPage from "./error-page";

import Header from "./navbar";

import Home from "./routes/home";

import StartTimes from "./routes/start-times";

// Total races -----------------------------------

import TotalRacesRoot, {
  loader as totalRacesRootLoader,
} from "./routes/total-races-root";

import { totalRacesLoader } from "./total-races";
import TotalRacesInstance from "./routes/total-races-instanace";

// Points -----------------------------------

import PointsDynamic, {
  loader as pointsRootLoader,
} from "./routes/points-root";

import { pointsLoader } from "./points";
import PointsInstance from "./routes/points-instance";

// Members -----------------------------------

import Members, { loader as membersRootLoader } from "./routes/members-root";

import { memberLoader } from "./members";
import MemberInstance from "./routes/member-instance";

import MemberIndex from "./routes/members-index";

// Racers -----------------------------------

import Races, { loader as racesRootLoader } from "./routes/races-root";

import { raceLoader } from "./races";
import RaceInstance from "./routes/race-instance";

// import RaceIndex from './routes/races-index';

// Other -----------------------------------

import ClubStats from "./routes/club-stats";

import Committee from "./routes/committee";

// data ------------------------------------------------

import dataMain from "./data/main.json";

// main app definition ------------------------------------------------

function App() {
  return (
    <>
      <Header />
      <Outlet />
    </>
  );
}

const router = createBrowserRouter(
  createRoutesFromElements(
    <>
      <Route path="/" element={<App />} errorElement={<ErrorPage />}>
        {/* Home -------------------------------------------------------*/}*/}
        <Route index element={<Home />} />
        {/* Members -------------------------------------------------------*/}
        */}
        <Route
          exact
          path="/members"
          element={<Members />}
          loader={membersRootLoader}
          errorElement={<ErrorPage />}
        >
          <Route index element={<MemberIndex />} />
          <Route
            path="/members/:memberId"
            element={<MemberInstance />}
            loader={memberLoader}
            errorElement={<ErrorPage />}
          ></Route>
        </Route>
        {/* Races -------------------------------------------------------*/}*/}
        <Route
          exact
          path="/races"
          element={<Races />}
          loader={racesRootLoader}
          errorElement={<ErrorPage />}
        >
          {/* <Route index element={<RaceIndex />}/> */}

          {/* Latest race redirect */}
          {dataMain.latestRace.date_ymd ? (
            <Route
              index
              element={
                <Navigate to={`/races/${dataMain.latestRace.date_ymd}`} />
              }
            />
          ) : (
            ""
          )}

          <Route
            path="/races/:raceId"
            element={<RaceInstance />}
            loader={raceLoader}
            errorElement={<ErrorPage />}
          ></Route>
        </Route>
        {/* Points dynamic -------------------------------------------------------*/}
        <Route
          exact
          path="/points"
          element={<PointsDynamic />}
          loader={pointsRootLoader}
          errorElement={<ErrorPage />}
        >
          {dataMain.latestRace.date_ymd ? (
            <Route
              index
              element={
                <Navigate to={`/points/${dataMain.latestPoints.season}`} />
              }
            />
          ) : (
            ""
          )}

          <Route
            path="/points/:pointsSeasonId"
            element={<PointsInstance />}
            loader={pointsLoader}
            errorElement={<ErrorPage />}
          ></Route>

          {/* <Route
            path ="/points/:raceId"
            element={<PointsInstance />}
            loader={raceLoader}
            errorElement={<ErrorPage />}>
          </Route> */}
        </Route>
        {/* Total Races -------------------------------------------------------*/}
        <Route
          exact
          path="/total-races"
          element={<TotalRacesRoot />}
          loader={totalRacesRootLoader}
          errorElement={<ErrorPage />}
        >
          {dataMain.latestRace.date_ymd ? (
            <Route
              index
              element={<Navigate to={`/total-races/${"byDistance"}`} />}
            />
          ) : (
            ""
          )}

          <Route
            path="/total-races/:totalRacesSeasonId"
            element={<TotalRacesInstance />}
            loader={totalRacesLoader}
            errorElement={<ErrorPage />}
          ></Route>

          {/* <Route
            path ="/points/:raceId"
            element={<PointsInstance />}
            loader={raceLoader}
            errorElement={<ErrorPage />}>
          </Route> */}
        </Route>
        {/* Start times -------------------------------------------------------*/}
        <Route path="/start-times" element={<StartTimes />} />
        <Route
          path="/pages/start_times"
          element={<Navigate to="/start-times" replace />}
        />
        {/* Race Stats -------------------------------------------------------*/}
        <Route path="/club-stats" element={<ClubStats />} />
        {/* Race Stats -------------------------------------------------------*/}
        <Route path="/committee" element={<Committee />} />
      </Route>
    </>
  )
);

createRoot(document.getElementById("root")).render(
  <StrictMode>
    <RouterProvider router={router} />
  </StrictMode>
);
