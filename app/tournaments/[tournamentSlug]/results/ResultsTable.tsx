import React from "react";
import {Table, Thead, Th, Tr, Td, Tbody, TableContainer, TableCaption, Link, List, ListItem} from '@chakra-ui/react'
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
                    <Link as={NextLink} href={`/tournaments/${tournamentSlug}`}>Go to the selections page.</Link>
                </TableCaption>
                <Thead><Tr>
                    <Th>Player</Th>
                    <Th isNumeric>Points</Th>
                    <Th>Picked teams</Th>
                </Tr></Thead>
                <Tbody>
                    {results.map((result) => buildRow(result))}
                </Tbody>
            </Table>
        </TableContainer>
    );
}
