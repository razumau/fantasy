import React from 'react';
import { Team } from "@/app/tournaments/[tournamentSlug]/types";
import { Table, Tr, Td, Tbody, TableContainer, Checkbox } from '@chakra-ui/react'

type TeamsTableProps = {
    teams: Team[];
    selectedTeamIds: number[];
    handleCheckboxChange: (selectedTeam: Team) => void;
    isOpen: boolean;
}

export default function TeamsTable({ teams, selectedTeamIds, handleCheckboxChange, isOpen }: TeamsTableProps) {
    const buildTableRow = (team: Team) =>{
        const checkbox = isOpen ?
            <Checkbox
                isChecked={selectedTeamIds.some(id => id === team.id)}
                onChange={(_e) => handleCheckboxChange(team)}
            /> : null;

        return <Tr key={team.id} _hover={{background: "#ebf8ff"}}>
            <Td>
                {checkbox}
            </Td>
            <Td>{team.name}</Td>
            <Td isNumeric>{team.price}</Td>
        </Tr>
    }

    return (
        <TableContainer>
            <Table variant='simple'>
                <Tbody>
                    {teams.map((team) => buildTableRow(team))}
                </Tbody>
            </Table>
        </TableContainer>
    );
}
