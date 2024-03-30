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
    tournament: Tournament;
    teams: Team[];
}

export const getServerSideProps: GetServerSideProps = async (context: GetServerSidePropsContext) => {
    const { tournamentSlug } = context.params as { tournamentSlug: string };
    const tournament = await fetchTournamentBySlug(tournamentSlug);
    if (!tournament) {
        return {
            redirect: {
                destination: '/404',
                permanent: false,
            },
        };
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