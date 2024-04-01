import React from 'react';
import { Team } from "@/app/tournaments/[tournamentSlug]/types";

type TeamsTableProps = {
    teams: Team[];
    selectedTeamIds: number[];
    handleCheckboxChange: (selectedTeam: Team) => void;
}

export default function TeamsTable({ teams, selectedTeamIds, handleCheckboxChange }: TeamsTableProps) {
    return (
        <div>
            <table className="bg-blue-50">
                <tbody>
                {teams.map((team) => (
                    <tr key={team.id}>
                        <td>
                            <input
                                type="checkbox"
                                checked={selectedTeamIds.some(id => id === team.id)}
                                onChange={(e) => handleCheckboxChange(team)}
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
