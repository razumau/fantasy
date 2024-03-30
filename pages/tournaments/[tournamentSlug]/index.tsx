import { GetServerSideProps, GetServerSidePropsContext } from 'next';
import { FC } from 'react';
import { fetchTournamentBySlug } from "@/src/services/tournamentService";

interface Tournament {
    id: string;
    name: string;
    slug: string;
}

interface Team {
    id: string;
    name: string;
}

interface TournamentTeamsPageProps {
    tournament: Tournament;
    teams: Team[];
}

export const getServerSideProps: GetServerSideProps = async (context: GetServerSidePropsContext) => {
    // Assume these functions are implemented elsewhere and return the correct types.
    const { tournamentSlug } = context.params as { tournamentSlug: string };
    const tournament = await fetchTournamentBySlug(tournamentSlug);
    // const teams = await fetchTeamsForTournament(tournament.id);

    return {
        props: {
            tournament: {slug: tournamentSlug},
            // teams,
        },
    };
};

const TournamentTeamsPage: FC<TournamentTeamsPageProps> = ({ tournament, teams }) => {
    return (
        <div>
            <h1>Teams for {tournament.slug}</h1>
            {/*<ul>*/}
            {/*    {teams.map(team => (*/}
            {/*        <li key={team.id}>{team.name}</li>*/}
            {/*    ))}*/}
            {/*</ul>*/}
        </div>
    );
};

export default TournamentTeamsPage;