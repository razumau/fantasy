import { fetchTournamentBySlug, fetchTeamsForTournament, fetchPicks } from "@/src/services/tournamentService";
import TournamentTeamsPage from './teams'

export default async function Page({ params }: { params: { tournamentSlug: string } }) {
    const tournament = await fetchTournamentBySlug(params.tournamentSlug);
    if (!tournament) {
        return {
            redirect: {
                destination: '/404',
                permanent: false,
            },
        };
    }

    const teams = await fetchTeamsForTournament(tournament.id);
    const picks = await fetchPicks(tournament.id)

    return <TournamentTeamsPage teams={teams} tournament={tournament} picks={picks} />
}
