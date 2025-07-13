import { Link } from "react-router-dom";

// Component --------------------------------------

export default function PointsRules({ season }) {
  // 2024-2025

  switch (season) {
    case "2024-2025":
      return (
        <>
          <h3>Participation</h3>
          <ul>
            <li>15 points per Sprint race</li>
            <li>
              30 points per Double Sprint, Palindrome Tri race, or other special
              events
            </li>
          </ul>

          <h3>Handicap</h3>
          <ul>
            <li>Up to 15 points per Sprint race</li>
            <li>Must race with a timing chip</li>
            <li>
              Must start at your handicapped-based{" "}
              <Link to="/start-times">Start Time</Link>
            </li>
            <li>
              Must complete the course before 7:30 to beat your handicap time
              and be eligible for points
            </li>
            <li>
              Each race, the competitor to beat their handicap by the most time
              will receive 15 points, the second 14, the third 13, etc. for up
              to 15 racers
            </li>
            <li>
              New start times are allocated whenever handicap times are beaten
            </li>
          </ul>
        </>
      );
      break;

    default:
      return (
        <>
          <h3>Participation</h3>
          <ul>
            <li>15 points per Sprint race</li>
            <li>
              30 points per Teams, Double Sprint, Long Tri, Palindrome Tri race,
              or other special events
            </li>
            <li>
              30 points per marshaling for first two occassions per season, 15
              points for all subsequent occassions in season
            </li>
          </ul>

          <h3>Handicap</h3>
          <ul>
            <li>Up to 15 points per Sprint race</li>
            <li>Must race with a timing chip</li>
            <li>
              Must start at your handicapped-based{" "}
              <Link to="/start-times">Start Time</Link>
            </li>
            <li>
              Must complete the course before 7:30 to beat your handicap time
              and be eligible for points
            </li>
            <li>
              Each race, the competitor to beat their handicap by the most time
              will receive 15 points, the second 14, the third 13, etc. for up
              to 15 racers
            </li>
            <li>
              New start times are allocated whenever handicap times are beaten
            </li>
          </ul>
        </>
      );
  }
}
