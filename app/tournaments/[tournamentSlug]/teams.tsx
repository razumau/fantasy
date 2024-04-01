'use client'

import TeamsSelector from "./TeamsSelector";
import {Tournament, Team} from "./types";

interface TournamentTeamsPageProps {
    tournament: Tournament;
    teams: Team[];
}

export default function TournamentTeamsPage({ tournament, teams }: TournamentTeamsPageProps) {
    return (
        <div className="min-h-screen bg-gray-100 p-4">
            <div className="mb-4 flex justify-between items-center">
                <h1 className="text-2xl font-bold">{tournament.title}</h1>
                <div className="text-right">
                    <p className="text-lg">Current User</p>
                    <a href="/logout" className="text-blue-500 hover:text-blue-700">Log out</a>
                </div>
            </div>

            <TeamsSelector teams={teams} tournament={tournament}>
            </TeamsSelector>
        </div>
    );
};
