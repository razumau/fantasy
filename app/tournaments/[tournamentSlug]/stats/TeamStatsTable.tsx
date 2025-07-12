import React from "react";
import {
    Table,
    Thead,
    Tbody,
    Tr,
    Th,
    Td,
    TableContainer,
    TableCaption,
    Badge,
    Text,
    Link
} from '@chakra-ui/react';
import NextLink from 'next/link';
import { TeamStats } from "@/src/services/statsService";

type TeamStatsTableProps = {
    teamStats: TeamStats[];
    tournamentSlug: string;
}

export default function TeamStatsTable({ teamStats, tournamentSlug }: TeamStatsTableProps) {
    const formatNumber = (num: number) => num.toFixed(2);
    
    const getErrorBadgeColor = (error: number) => {
        if (error > 10) return 'red';
        if (error > 0) return 'orange';
        if (error > -10) return 'yellow';
        return 'green';
    };

    return (
        <TableContainer>
            <Table variant="simple" size="sm">
                <TableCaption placement="top">
                    <Text mb={1}>{teamStats.length} teams</Text>
                    <Text mb={1}><Link as={NextLink} href={`/tournaments/${tournamentSlug}`}>Go to the selections page</Link></Text>
                    <Text mb={1}><Link as={NextLink} href={`/tournaments/${tournamentSlug}/results`}>View tournament results</Link></Text>
                    <Text><Link as={NextLink} href={`/tournaments/${tournamentSlug}/popular`}>What are the most popular teams?</Link></Text>
                </TableCaption>
                <Thead>
                    <Tr>
                        <Th>Team</Th>
                        <Th isNumeric>Price</Th>
                        <Th isNumeric>Points</Th>
                        <Th isNumeric>Difference</Th>
                    </Tr>
                </Thead>
                <Tbody>
                    {teamStats.map((team) => (
                        <Tr key={team.id}>
                            <Td>
                                <Text fontWeight="medium">{team.name}</Text>
                            </Td>
                            <Td isNumeric>{team.price}</Td>
                            <Td isNumeric>
                                <Text fontWeight="bold">{team.points}</Text>
                            </Td>
                            <Td isNumeric>
                                <Badge colorScheme={getErrorBadgeColor(team.difference)}>
                                    {team.difference > 0 ? '+' : ''}{formatNumber(team.difference)}
                                </Badge>
                            </Td>
                        </Tr>
                    ))}
                </Tbody>
            </Table>
        </TableContainer>
    );
}
