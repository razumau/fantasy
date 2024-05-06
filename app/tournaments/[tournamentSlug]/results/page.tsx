import { fetchTournamentBySlug } from "@/src/services/tournamentService";
import {fetchTournamentResults, fetchIdealPick} from "@/src/services/resultsService";
import React from "react";
import Results from "@/app/tournaments/[tournamentSlug]/results/Results";

export default async function Page({ params }: { params: { tournamentSlug: string } }) {
    const tournament = await fetchTournamentBySlug(params.tournamentSlug);
    if (!tournament) {
        throw new Error('There is no tournament with this ID');
    }

    const results = await fetchTournamentResults(tournament.id);
    const idealPick = await fetchIdealPick(tournament.id);

    return <Results results={results}
                    tournament={{ slug: params.tournamentSlug, title: tournament.title }}
                    idealPick={idealPick}/>
}
