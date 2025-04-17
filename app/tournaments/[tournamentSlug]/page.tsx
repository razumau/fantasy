import { Metadata, ResolvingMetadata } from 'next/types'
import { fetchTournamentBySlug, fetchTeamsForTournament, fetchPicks } from "@/src/services/tournamentService";
import TournamentTeamsPage from './teams'

type Props = {
    params: { tournamentSlug: string }
}

export async function generateMetadata(
    { params }: Props,
    parent: ResolvingMetadata
): Promise<Metadata> {
    const tournament = await fetchTournamentBySlug(params.tournamentSlug)

    if (!tournament) {
        return {
            title: ''
        }
    }

    return {
        title: `Fantasy — ${tournament.title}`,
        description: `Fantasy tournament: ${tournament.title}`,
        openGraph: {
            title: `Fantasy — ${tournament.title}`,
            description: `Fantasy tournament: ${tournament.title}`
        }
    }
}

export default async function Page({ params }: { params: { tournamentSlug: string } }) {
    const tournament = await fetchTournamentBySlug(params.tournamentSlug);
    if (!tournament) {
        throw new Error('There is no tournament with this ID');
    }

    const teams = await fetchTeamsForTournament(tournament.id);
    const picks = await fetchPicks(tournament.id)

    return <TournamentTeamsPage teams={teams} tournament={tournament} picks={picks} />
}
