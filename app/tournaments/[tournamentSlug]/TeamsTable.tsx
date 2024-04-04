import React from 'react';
import { Team } from "@/app/tournaments/[tournamentSlug]/types";
import { Table, Tr, Td, Tbody, TableContainer, Checkbox } from '@chakra-ui/react'

type TeamsTableProps = {
    teams: Team[];
    selectedTeamIds: number[];
    handleCheckboxChange: (selectedTeam: Team) => void;
}

export default function TeamsTable({ teams, selectedTeamIds, handleCheckboxChange }: TeamsTableProps) {
    return (
        <TableContainer>
            <Table variant='simple'>
                <Tbody>
                    {teams.map((team) => (
                        <Tr key={team.id} _hover={{background: "#ebf8ff"}}>
                            <Td>
                                <Checkbox
                                    isChecked={selectedTeamIds.some(id => id === team.id)}
                                    onChange={(_e) => handleCheckboxChange(team)}
                                />
                            </Td>
                            <Td>{team.name}</Td>
                            <Td isNumeric>{team.price}</Td>
                        </Tr>
                    ))}
                </Tbody>
            </Table>
        </TableContainer>
    );
}
