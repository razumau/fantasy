import PopularTeamsTable from "@/app/tournaments/[tournamentSlug]/popular/PopularTeamsTable";
import {TeamPopularity, Tournament} from "@/app/tournaments/[tournamentSlug]/popular/types";
import React from "react";
import {Box, Flex, Grid, Heading} from "@chakra-ui/react";
import {UserButton} from "@clerk/nextjs";

type PopularTeamsProps = {
    teams: TeamPopularity[];
    usersWithPickCount: number;
    tournament: Tournament;
}

export default function PopularTeams({ teams, usersWithPickCount, tournament }: PopularTeamsProps) {
    return <Box minH="100vh">
            <Flex justifyContent="flex-end" p={4}>
                <UserButton/>
            </Flex>
            <Heading textAlign={'center'} mx={2}>{tournament.title}</Heading>
            <Grid templateColumns={{base: "repeat(1, 1fr)", md: "repeat(3, 1fr)"}} gap={4}>
                <Box display={{base: "block", md: "block"}} order={{base: 1, md: 3}}>
                </Box>

                <Box order={{base: 2, md: 2}}>
                    <PopularTeamsTable teams={teams}
                                       usersWithPickCount={usersWithPickCount}
                                       tournamentSlug={tournament.slug}/>
                </Box>

                <Box display={{base: "none", md: "block"}} order={{md: 1}}></Box>
            </Grid>
        </Box>
}