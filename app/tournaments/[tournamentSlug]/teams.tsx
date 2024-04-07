'use client'

import TeamsSelector from "./TeamsSelector";
import {Tournament, Team, Picks} from "./types";
import {Heading} from "@chakra-ui/react";

interface TournamentTeamsPageProps {
    tournament: Tournament;
    teams: Team[];
    picks: Picks;
}

export default function TournamentTeamsPage({ tournament, teams, picks }: TournamentTeamsPageProps) {
    return <>
        <Heading textAlign={'center'} mx={2}>{tournament.title}</Heading>
        <TeamsSelector teams={teams} tournament={tournament} picks={picks}/>
    </>;
};
