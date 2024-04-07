import { fetchTournamentBySlug, fetchPopularTeamsForTournament } from "@/src/services/tournamentService";
import React from "react";
import PopularTeams from "@/app/tournaments/[tournamentSlug]/popular/PopularTeams";

export default async function Page({ params }: { params: { tournamentSlug: string } }) {
    const tournament = await fetchTournamentBySlug(params.tournamentSlug);
    if (!tournament) {
        throw new Error('There is no tournament with this ID');
    }

    const {teamsByPopularity, usersWithPickCount} = await fetchPopularTeamsForTournament(tournament.id);

    return <PopularTeams teams={teamsByPopularity}
                         usersWithPickCount={usersWithPickCount}
                         tournament={{ slug: params.tournamentSlug, title: tournament.title }}/>
}
