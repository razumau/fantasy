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
                    <Text>Based on picks made by {usersWithPickCount} players.</Text>
                    <Link as={NextLink} href={`/tournaments/${tournamentSlug}`}>Go to the selections page.</Link>
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