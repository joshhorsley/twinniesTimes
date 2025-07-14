import {
  Outlet,
  NavLink,
  useLoaderData,
  Form,
  // redirect,
  useNavigation,
  useSubmit,
} from "react-router-dom";

import { Row } from "react-bootstrap";

import { getBestTimesSeasons } from "../best-times";
import { useEffect } from "react";

export async function loader({ request }) {
  const url = new URL(request.url);
  const q = url.searchParams.get("q");
  const seasons = await getBestTimesSeasons(q);
  return { seasons, q };
}

import { toggleNav, removeNav } from "../sidebar";

export default function BestTimes() {
  const { seasons, q } = useLoaderData();
  const navigation = useNavigation();
  const submit = useSubmit();

  const searching =
    navigation.location &&
    new URLSearchParams(navigation.location.search).has("q");

  useEffect(() => {
    document.getElementById("q").value = q;
  }, [q]);

  return (
    <>
      <div id="sidebar" className="sidebar hidden">
        <a className="closebtn" onClick={() => toggleNav()}>
          ×
        </a>
        <div>
          <Form id="search-form" role="search">
            <input
              id="q"
              className={searching ? "loading" : ""}
              aria-label="Search seasons"
              placeholder="Search seasons"
              type="search"
              name="q"
              defaultValue={q}
              onChange={(event) => {
                const isFirstSearch = q == null;
                submit(event.currentTarget.form, { replace: !isFirstSearch });
              }}
            />
            <div id="search-spinner" aria-hidden hidden={!searching} />
            <div className="sr-only" aria-live="polite"></div>
          </Form>
        </div>

        <nav id="sidebarScroll">
          {seasons.length ? (
            <>
              {seasons.map((season) => (
                <ul key={season.season}>
                  <NavLink
                    to={season.season}
                    className={({ isActive, isPending }) =>
                      isActive ? "active" : isPending ? "pending" : ""
                    }
                    onClick={() => removeNav()}
                  >
                    {season.season_display ? (
                      <>{season.season_display}</>
                    ) : (
                      <i>No Name</i>
                    )}

                    {/* {" "} */}
                  </NavLink>
                </ul>
              ))}
            </>
          ) : (
            <p>
              <i>No Seasons</i>
            </p>
          )}
        </nav>
      </div>
      <div className="contentScroll contentHasSidebar">
        <Row className="rowBtnToggle">
          <button className="btnToggle" onClick={() => toggleNav()}>
            ☰ Show Seasons
          </button>
        </Row>
        <Outlet />
      </div>
    </>
  );
}
