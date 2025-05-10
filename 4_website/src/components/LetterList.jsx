// import dataClubstats from "../data/clubMetrics.json";

// const eventLetters = dataClubstats.eventLetters;

export default function LetterList({eventLetters}) {

    return(
        <details>
            <summary>Event letters (weird bug: these sometimes don&apos;t all appear, refresh to fix)</summary>
            {/* <p>Refresh page if these don&apos;t appear on plot</p> */}

            <ul>
                {
                    
                    
                    
                    eventLetters.map((e, i) => {
                        
                        return(
                            
                            <li key={i}>
                                {e.letter}: {e.text}
                                </li>
                
            )

            })
            }
            </ul>
        </details>    
    )
    
}