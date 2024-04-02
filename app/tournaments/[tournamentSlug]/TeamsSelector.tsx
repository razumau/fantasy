import { useState } from 'react';
import TeamsTable from "./TeamsTable";
import SelectedTeams from "./SelectedTeams";
import {savePicks} from "@/app/actions";
import {Tournament, Team, Picks} from "./types";

interface SelectionState {
    selectedTeams: Team[];
    totalSelectedPrice: number;
    version: number;
}

interface TeamsSelectorProps {
    teams: Team[];
    tournament: Tournament;
    picks: Picks;
}

export default function TeamsSelector({ teams, tournament, picks }: TeamsSelectorProps) {
    const [selection, setSelection] = useState<SelectionState>(
        { selectedTeams: picks.teams, totalSelectedPrice: picks.totalSelectedPrice, version: picks.version });

    const handleCheckboxChange = async (selectedTeam: Team) => {
        const removingTeam = selection.selectedTeams.find(team => team.id === selectedTeam.id);
        let newState: SelectionState;

        if (removingTeam) {
            newState = {
                selectedTeams: selection.selectedTeams.filter(team => team.id !== selectedTeam.id),
                totalSelectedPrice: selection.totalSelectedPrice - selectedTeam.price,
                version: selection.version + 1,
            }
        } else {
            if (selection.selectedTeams.length < tournament.maxTeams
                    && (selection.totalSelectedPrice + selectedTeam.price) <= tournament.maxPrice) {
                newState = {
                    selectedTeams: [...selection.selectedTeams, selectedTeam],
                    totalSelectedPrice: selection.totalSelectedPrice + selectedTeam.price,
                    version: selection.version + 1,
                }
            } else {
                newState = selection;
            }
        }
        if (selection.version == newState.version) {
            return;
        }

        setSelection(newState);

        try {
            await savePicks({
                teamIds: newState.selectedTeams.map(team => team.id),
                tournamentId: tournament.id,
                version: newState.version
            });
        } catch {
            setSelection(selection);
        }
    };

    const selectedTeamIds = selection.selectedTeams.map(team => team.id);

    return (
        <>
            <div className="flex flex-col md:flex-row gap-4">
                <div className="flex-grow md:w-2/3 bg-white shadow rounded-lg p-4">
                    <TeamsTable teams={teams}
                                selectedTeamIds={selectedTeamIds}
                                handleCheckboxChange={handleCheckboxChange}
                    />
                </div>
            </div>
            <div className="md:w-1/3 bg-white shadow rounded-lg p-4">
                <SelectedTeams teams={selection.selectedTeams}></SelectedTeams>
            </div>
        </>
    )
}