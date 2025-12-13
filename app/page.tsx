import {Container, Box, Heading, Link, Text, Table, Thead, Tbody, Tr, Th, Td, TableContainer} from '@chakra-ui/react';
import NextLink from "next/link";
import React from "react";
import { fetchOpenTournaments, fetchClosedTournaments, fetchClosedTournamentsWithWinners } from '@/src/services/tournamentService';

interface PageProps {
    searchParams: { winners?: string };
}

interface TournamentWithWinners {
    title: string;
    slug: string;
    deadline: Date;
    winners: {
        username: string;
        points: number;
    }[];
    idealPoints: number;
    numberOfPlayers: number;
}

export default async function HomePage({ searchParams }: PageProps) {
    const openTournaments = await fetchOpenTournaments();
    const showWinners = searchParams.winners === 'true';
    const closedTournaments = showWinners 
        ? await fetchClosedTournamentsWithWinners()
        : await fetchClosedTournaments();

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
                ) : showWinners ? (
                    <TableContainer maxW='100%' overflowX='auto'>
                        <Table variant='simple' size='sm' maxW='1000px'>
                            <Thead>
                                <Tr>
                                    <Th width='40%'>Title</Th>
                                    <Th width='10%' isNumeric>Players</Th>
                                    <Th width='25%'>Winner(s)</Th>
                                    <Th width='12.5%' isNumeric>Points</Th>
                                    <Th width='12.5%' isNumeric>Max Points</Th>
                                </Tr>
                            </Thead>
                            <Tbody>
                                {closedTournaments.map(tournament => {
                                    const tournamentWithWinners = tournament as TournamentWithWinners;
                                    return (
                                        <Tr key={tournament.slug}>
                                            <Td>
                                                <Link as={NextLink} href={`/tournaments/${tournament.slug}/results`}>
                                                    {tournament.title}
                                                </Link>
                                            </Td>
                                            <Td isNumeric>{tournamentWithWinners.numberOfPlayers}</Td>
                                            <Td>
                                                {tournamentWithWinners.winners.length > 0 ? (
                                                    tournamentWithWinners.winners.map((winner, index) => (
                                                        <Text key={index} fontSize='sm'>
                                                            {winner.username}
                                                        </Text>
                                                    ))
                                                ) : (
                                                    <Text fontSize='sm' color='gray.500'>No players</Text>
                                                )}
                                            </Td>
                                            <Td isNumeric>
                                                {tournamentWithWinners.winners.length > 0 
                                                    ? tournamentWithWinners.winners[0].points
                                                    : '-'
                                                }
                                            </Td>
                                            <Td isNumeric>{tournamentWithWinners.idealPoints}</Td>
                                        </Tr>
                                    );
                                })}
                            </Tbody>
                        </Table>
                    </TableContainer>
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
