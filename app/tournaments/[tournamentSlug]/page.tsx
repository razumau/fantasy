import { Metadata, ResolvingMetadata } from 'next/types'
import { fetchTournamentBySlug, fetchTeamsForTournament, fetchPicks } from "@/src/services/tournamentService";
import TournamentTeamsPage from './teams'

type Props = {
    params: Promise<{ tournamentSlug: string }>
}

export async function generateMetadata(
    props: Props,
    parent: ResolvingMetadata
): Promise<Metadata> {
    const params = await props.params
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

export default async function Page(props: { params: Promise<{ tournamentSlug: string }> }) {
    const params = await props.params;
    const tournament = await fetchTournamentBySlug(params.tournamentSlug);
    if (!tournament) {
        throw new Error('There is no tournament with this ID');
    }

    const teams = await fetchTeamsForTournament(tournament.id);
    const picks = await fetchPicks(tournament.id)

    return <TournamentTeamsPage teams={teams} tournament={tournament} picks={picks} />
}
