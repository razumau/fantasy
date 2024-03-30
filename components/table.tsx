import React, { useState } from 'react';

interface Team {
    id: number;
    name: string;
    price: number;
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

    const handleCheckboxChange = (selectedTeam: Team) => {
        setSelection((currentState) => {
            const isAlreadySelected = currentState.selectedTeams.find(team => team.id === selectedTeam.id);

            if (isAlreadySelected) {
                const updatedTeams = currentState.selectedTeams.filter(team => team.id !== selectedTeam.id);
                const updatedTotalPrice = updatedTeams.reduce((acc, team) => acc + team.price, 0);
                return { selectedTeams: updatedTeams, totalSelectedPrice: updatedTotalPrice };
            } else {
                if (currentState.selectedTeams.length < maxTeams && (currentState.totalSelectedPrice + selectedTeam.price) <= maxPrice) {
                    const updatedTeams = [...currentState.selectedTeams, selectedTeam];
                    const updatedTotalPrice = currentState.totalSelectedPrice + selectedTeam.price;
                    return { selectedTeams: updatedTeams, totalSelectedPrice: updatedTotalPrice };
                }
            }
            return currentState;
        });
    };

    const handleSave = async () => {
        const response = await fetch('/api/save-picks', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ ids: selection.selectedTeams.map(team => team.id) }),
        });

        if (response.ok) {
            console.log('Selections saved successfully');
        } else {
            console.error('Failed to save selections');
        }
    };

    return (
        <div>
            <p>Points available: {maxPrice - selection.totalSelectedPrice}</p>
            <p>Points used: {selection.totalSelectedPrice}</p>
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
