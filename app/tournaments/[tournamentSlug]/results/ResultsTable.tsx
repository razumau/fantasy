import React from "react";
import {Table, Thead, Th, Tr, Td, Tbody, TableContainer, TableCaption, Link, List, ListItem} from '@chakra-ui/react'
import {Result} from "@/app/tournaments/[tournamentSlug]/results/types";
import NextLink from 'next/link'

type ResultsTableProps = {
    results: Result[];
    tournamentSlug: string;
}

export default function ResultsTable({ results, tournamentSlug }: ResultsTableProps) {
    const calculateRank = (results: Result[]) => {
        let rank = 0, prevPoints = -1;
        return results.map((result, index) => {
            if (result.points !== prevPoints) {
                rank = index + 1;
            }
            prevPoints = result.points;
            return {...result, rank};
        });
    }

    const rankedResults = calculateRank(results);

    const buildRow = (result: Result, index: number) => {
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
                    <Link as={NextLink} href={`/tournaments/${tournamentSlug}`}>Go to the selections page</Link>
                </TableCaption>
                <Thead><Tr>
                    <Th>#</Th>
                    <Th>Player</Th>
                    <Th isNumeric>Points</Th>
                    <Th>Picked teams</Th>
                </Tr></Thead>
                <Tbody>
                    {rankedResults.map((result, index) => buildRow(result, index))}
                </Tbody>
            </Table>
        </TableContainer>
    );
}
