import { GetServerSideProps, GetServerSidePropsContext } from 'next';
import { FC } from 'react';
import { fetchTournamentBySlug, fetchTeamsForTournament } from "@/src/services/tournamentService";
import TeamsTable from "@/components/table"

interface Tournament {
    id: string;
    title: string;
    slug: string;
}

interface Team {
    id: number;
    name: string;
    price: number;
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
            <h1>{tournament.title}</h1>
            <TeamsTable teams={teams} maxTeams={5} maxPrice={150}></TeamsTable>
        </div>
    );
};

export default TournamentTeamsPage;