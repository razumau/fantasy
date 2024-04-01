import React, { useState } from 'react';
import { savePicks } from '@/app/actions'

interface Team {
    id: number;
    name: string;
    price: number;
    tournamentId: number;
}

interface SelectionState {
    selectedTeams: Team[];
    totalSelectedPrice: number;
}

interface TeamTableProps {
    teams: Team[];
    maxTeams: number;
    maxPrice: number;
}

const TeamsTable: React.FC<TeamTableProps> = ({ teams, maxTeams, maxPrice }) => {
    const [selection, setSelection] = useState<SelectionState>({ selectedTeams: [], totalSelectedPrice: 0 });

    const handleCheckboxChange = async (selectedTeam: Team) => {
        const removingTeam = selection.selectedTeams.find(team => team.id === selectedTeam.id);
        let newState: SelectionState;

        if (removingTeam) {
            newState = {
                selectedTeams: selection.selectedTeams.filter(team => team.id !== selectedTeam.id),
                totalSelectedPrice: selection.totalSelectedPrice - selectedTeam.price
            }
        } else {
            if (selection.selectedTeams.length < maxTeams && (selection.totalSelectedPrice + selectedTeam.price) <= maxPrice) {
                newState = {
                    selectedTeams: [...selection.selectedTeams, selectedTeam],
                    totalSelectedPrice: selection.totalSelectedPrice + selectedTeam.price
                }
            } else {
                newState = selection;
            }
        }
        const previousState = selection;
        setSelection(newState);

        try {
            await savePicks(newState.selectedTeams.map(({ id, tournamentId }) => ({ id, tournamentId })));
        } catch {
            setSelection(previousState);
        }
    };

    return (
        <div>
            <table className="bg-blue-50">
                <tbody>
                {teams.map((team) => (
                    <tr key={team.id}>
                        <td>
                            <input
                                type="checkbox"
                                checked={selection.selectedTeams.some(selectedTeam => selectedTeam.id === team.id)}
                                onChange={() => handleCheckboxChange(team)}
                            />
                        </td>
                        <td>{team.name}</td>
                        <td>{team.price}</td>
                    </tr>
                ))}
                </tbody>
            </table>
                </div>
                );
            }

export default TeamsTable;
