import React from "react";
import {fetchTournamentBySlug, fetchTeamsForTournament} from "@/src/services/tournamentService";
import {fetchAdminStatus} from "@/src/services/userService";
import Edit from "@/app/tournaments/[tournamentSlug]/edit/EditTournament";

export default async function Page(props: { params: Promise<{ tournamentSlug: string }> }) {
    const params = await props.params;
    const isAdmin = await fetchAdminStatus();
    if (!isAdmin) {
        throw new Error('You are not allowed here');
    }

    const tournament = await fetchTournamentBySlug(params.tournamentSlug);
    if (!tournament) {
        throw new Error('Tournament not found');
    }
    
    const teams = await fetchTeamsForTournament(tournament.id);

    return <Edit tournament={tournament} teams={teams}/>
}
