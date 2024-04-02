'use client'

import TeamsSelector from "./TeamsSelector";
import {Tournament, Team, Picks} from "./types";
import { UserButton } from "@clerk/nextjs";
import {Box, Flex, Heading} from "@chakra-ui/react";

interface TournamentTeamsPageProps {
    tournament: Tournament;
    teams: Team[];
    picks: Picks;
}

export default function TournamentTeamsPage({ tournament, teams, picks }: TournamentTeamsPageProps) {
    return (
        <Box minH="100vh">
            <Flex justifyContent="flex-end" p={4}>
                <UserButton/>
            </Flex>
            <Heading>{tournament.title}</Heading>
            <TeamsSelector teams={teams} tournament={tournament} picks={picks}>
            </TeamsSelector>
        </Box>
    );
};
