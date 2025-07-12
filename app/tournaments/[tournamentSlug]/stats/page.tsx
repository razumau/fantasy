import { fetchTournamentBySlug } from "@/src/services/tournamentService";
import { fetchIdealPick } from "@/src/services/resultsService";
import { fetchTeamStats, fetchTournamentMetrics } from "@/src/services/statsService";
import React from "react";
import Stats from "@/app/tournaments/[tournamentSlug]/stats/Stats";

export default async function Page({ params }: { params: { tournamentSlug: string } }) {
    const tournament = await fetchTournamentBySlug(params.tournamentSlug);
    if (!tournament) {
        throw new Error('There is no tournament with this ID');
    }

    const idealPick = await fetchIdealPick(tournament.id);
    const teamStats = await fetchTeamStats(tournament.id);
    const tournamentMetrics = await fetchTournamentMetrics(tournament.id);

    return <Stats 
        tournament={{ slug: params.tournamentSlug, title: tournament.title, id: tournament.id }}
        idealPick={idealPick}
        teamStats={teamStats}
        tournamentMetrics={tournamentMetrics}
    />
}
