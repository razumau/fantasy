import { fetchTournamentBySlug, fetchTeamsForTournament } from "@/src/services/tournamentService";
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

    return <TournamentTeamsPage teams={teams} tournament={tournament} />
}
