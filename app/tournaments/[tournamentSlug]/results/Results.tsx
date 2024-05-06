import React from "react";
import {Box, Grid, Heading} from "@chakra-ui/react";
import {IdealPick, Result, Tournament} from "@/app/tournaments/[tournamentSlug]/results/types";
import ResultsTable from "@/app/tournaments/[tournamentSlug]/results/ResultsTable";
import IdealPickBox from "@/app/tournaments/[tournamentSlug]/results/IdealPickBox";

type ResultsProps = {
    results: Result[];
    tournament: Tournament;
    idealPick: IdealPick;
}

export default function Results({ results, tournament, idealPick }: ResultsProps) {
    return <>
        <Heading textAlign={'center'} mx={2}>{tournament.title}</Heading>
        <Grid templateColumns={{base: "repeat(1, 1fr)", md: "repeat(3, 1fr)"}} gap={4}>
            <Box display={{base: "block", md: "block"}} order={{base: 1, md: 3}}>
            </Box>

            <Box order={{base: 2, md: 2}}>
                <IdealPickBox idealPick={idealPick}/>
                <ResultsTable results={results} tournamentSlug={tournament.slug}/>
            </Box>

            <Box display={{base: "none", md: "block"}} order={{md: 1}}></Box>
        </Grid>
    </>
}
