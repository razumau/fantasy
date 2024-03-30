import { GetServerSideProps, GetServerSidePropsContext } from 'next';
import { FC } from 'react';
import { fetchTournamentBySlug, fetchTeamsForTournament } from "@/src/services/tournamentService";

interface Tournament {
    id: string;
    title: string;
    slug: string;
}

interface Team {
    id: number;
    tournamentId: number;
}

interface TournamentTeamsPageProps {
    tournament: Tournament | null;
    teams: Team[];
}

export const getServerSideProps: GetServerSideProps = async (context: GetServerSidePropsContext) => {
    const { tournamentSlug } = context.params as { tournamentSlug: string };
    const tournament = await fetchTournamentBySlug(tournamentSlug);
    if (!tournament) {
        return {
            props: {
                tournament: null,
                teams: [],
            }
        }
    }

    const teams = await fetchTeamsForTournament(tournament.id);

    return {
        props: {
            tournament,
            teams,
        },
    };
};

const TournamentTeamsPage: FC<TournamentTeamsPageProps> = ({ tournament, teams }) => {
    if (!tournament) {
        return (
            <div>
                No tournament found for this URL.
            </div>
        )
    }
    return (
        <div>
            <h1>Teams for {tournament.title}</h1>
            <ul>
                {teams.map(team => (
                    <li key={team.id}>{team.name}</li>
                ))}
            </ul>
        </div>
    );
};

export default TournamentTeamsPage;