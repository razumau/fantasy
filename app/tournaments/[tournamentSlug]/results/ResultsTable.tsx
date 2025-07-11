import React from "react";
import {
    Table,
    Thead,
    Th,
    Tr,
    Td,
    Tbody,
    TableContainer,
    TableCaption,
    Link,
    List,
    ListItem,
    Text
} from '@chakra-ui/react'
import {Result} from "@/app/tournaments/[tournamentSlug]/results/types";
import NextLink from 'next/link'

type ResultsTableProps = {
    results: Result[];
    tournamentSlug: string;
}

export default function ResultsTable({ results, tournamentSlug }: ResultsTableProps) {
    const buildRow = (result: Result) => {
        const teamsCell = result.teams.map(team => {
            const teamLine = `${team.name} (${team.price}) — ${team.points}`
            return <ListItem key={team.id}>{teamLine}</ListItem>;
        });

        return <Tr key={result.userId} _hover={{background: "#ebf8ff"}}>
            <Td>{result.rank}</Td>
            <Td>{result.username}</Td>
            <Td isNumeric>{result.points}</Td>
            <Td>
                <List spacing={2}>{teamsCell}</List>
            </Td>
        </Tr>;
    }

    return (
        <TableContainer>
            <Table variant='simple'>
                <TableCaption placement="top">
                    <Text mb={1}>{results.length} players</Text>
                    <Text mb={1}><Link as={NextLink} href={`/tournaments/${tournamentSlug}`}>Go to the selections page</Link></Text>
                    <Text><Link as={NextLink} href={`/tournaments/${tournamentSlug}/popular`}>What are the most popular teams?</Link></Text>
                </TableCaption>
                <Thead><Tr>
                    <Th>#</Th>
                    <Th>Player</Th>
                    <Th isNumeric>Points</Th>
                    <Th>Picked teams</Th>
                </Tr></Thead>
                <Tbody>
                    {results.map((result, index) => buildRow(result))}
                </Tbody>
            </Table>
        </TableContainer>
    );
}
