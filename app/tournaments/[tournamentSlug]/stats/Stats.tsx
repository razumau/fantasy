import React from "react";
import { Box, Grid, Heading } from '@chakra-ui/react';
import { TeamStats, TournamentMetrics } from "@/src/services/statsService";
import { IdealPick } from "@/app/tournaments/[tournamentSlug]/results/types";
import IdealPickBox from "@/app/tournaments/[tournamentSlug]/results/IdealPickBox";
import TeamStatsTable from "./TeamStatsTable";
import TournamentMetricsComponent from "./TournamentMetrics";

type StatsProps = {
    tournament: {
        slug: string;
        title: string;
        id: number;
    };
    idealPick: IdealPick;
    teamStats: TeamStats[];
    tournamentMetrics: TournamentMetrics;
}

export default function Stats({ tournament, idealPick, teamStats, tournamentMetrics }: StatsProps) {
    return <>
        <Heading textAlign={'center'} mx={2}>{tournament.title}</Heading>
        <Grid templateColumns={{base: "repeat(1, 1fr)", md: "repeat(3, 1fr)"}} gap={4}>
            <Box display={{base: "block", md: "block"}} order={{base: 1, md: 3}}>
            </Box>

            <Box order={{base: 2, md: 2}}>
                <TournamentMetricsComponent metrics={tournamentMetrics} />
                <IdealPickBox idealPick={idealPick} />
                <TeamStatsTable teamStats={teamStats} tournamentSlug={tournament.slug} />
            </Box>

            <Box display={{base: "none", md: "block"}} order={{md: 1}}></Box>
        </Grid>
    </>
}
