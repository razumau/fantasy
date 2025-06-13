import { Table, Thead, Th, Tr, Td, Tbody, TableContainer, TableCaption, Text, Link } from '@chakra-ui/react'
import React from "react";
import {TeamPopularity} from "@/app/tournaments/[tournamentSlug]/popular/types";
import NextLink from 'next/link'

type PopularTeamsTableProps = {
    teams: TeamPopularity[];
    usersWithPickCount: number;
    tournamentSlug: string;
}

export default function PopularTeamsTable({ teams, usersWithPickCount, tournamentSlug }: PopularTeamsTableProps) {
    return (
        <TableContainer>
            <Table variant='simple'>
                <TableCaption placement="top">
                    <Text mb={1}>Based on picks made by {usersWithPickCount} players</Text>
                    <Text mb={1}><Link as={NextLink} href={`/tournaments/${tournamentSlug}`}>Go to the selections page</Link></Text>
                    <Text><Link as={NextLink} href={`/tournaments/${tournamentSlug}/results`}>Go to the results page</Link></Text>
                </TableCaption>
                <Thead><Tr>
                    <Th>Team</Th>
                    <Th isNumeric>Players</Th>
                    <Th isNumeric>% of players</Th>
                </Tr></Thead>
                <Tbody>
                    {teams.map((team) =>
                        <Tr key={team.id} _hover={{background: "#ebf8ff"}}>
                            <Td>{team.name}</Td>
                            <Td isNumeric>{team.count}</Td>
                            <Td isNumeric>{team.percentage}</Td>
                        </Tr>
                    )}
                </Tbody>
            </Table>
        </TableContainer>
    );
}