import React from "react";
import {fetchOrCreateTournament, fetchTeamsForTournament} from "@/src/services/tournamentService";
import {fetchAdminStatus} from "@/src/services/userService";
import Edit from "@/app/tournaments/[tournamentSlug]/edit/EditTournament";

export default async function Page({ params }: { params: { tournamentSlug: string } }) {
    const isAdmin = await fetchAdminStatus();
    if (!isAdmin) {
        throw new Error('You are not allowed here');
    }

    const tournament = await fetchOrCreateTournament(params.tournamentSlug);
    const teams = await fetchTeamsForTournament(tournament.id);
    const teamsStr = teams.map(team => `${team.name} ${team.price} ${team.points}`).join('\n')

    return <Edit tournament={tournament} teams={teamsStr}/>
}
