import {Container, Box, Heading, Link, Text} from '@chakra-ui/react';
import NextLink from "next/link";
import React from "react";
import { fetchOpenTournaments, fetchClosedTournaments } from '@/src/services/tournamentService';

export default async function HomePage() {
    const openTournaments = await fetchOpenTournaments();
    const closedTournaments = await fetchClosedTournaments();

    return (
        <Container maxW='4xl' centerContent>
            <Box maxW='2xl'>
                <Heading pb='2' as='h2' size='lg'>These tournaments are active:</Heading>
                {openTournaments.length === 0 ? (
                    <Text pt='2' color='gray.500'>No active tournaments</Text>
                ) : (
                    openTournaments.map(tournament => (
                        <Text key={tournament.slug} pt='2'>
                            <Link as={NextLink} href={`/tournaments/${tournament.slug}`}>
                                {tournament.title}
                            </Link>
                        </Text>
                    ))
                )}
                
                <Heading pt='4' pb='2' as='h2' size='lg'>See results for completed tournaments:</Heading>
                {closedTournaments.length === 0 ? (
                    <Text pt='2' color='gray.500'>No completed tournaments</Text>
                ) : (
                    closedTournaments.map(tournament => (
                        <Text key={tournament.slug} pt='2'>
                            <Link as={NextLink} href={`/tournaments/${tournament.slug}/results`}>
                                {tournament.title}
                            </Link>
                        </Text>
                    ))
                )}
            </Box>
        </Container>
    );
}
