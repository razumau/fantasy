'use client'

import TeamsSelector from "./TeamsSelector";
import {Tournament, Team} from "./types";
import { UserButton } from "@clerk/nextjs";

interface TournamentTeamsPageProps {
    tournament: Tournament;
    teams: Team[];
    picks: Team[];
}

export default function TournamentTeamsPage({ tournament, teams, picks }: TournamentTeamsPageProps) {
    return (
        <div className="min-h-screen bg-gray-100 p-4">
            <div className="mb-4 flex justify-between items-center">
                <h1 className="text-2xl font-bold">{tournament.title}</h1>
                <div className="text-right">
                    <UserButton/>
                </div>
            </div>

            <TeamsSelector teams={teams} tournament={tournament} picks={picks}>
            </TeamsSelector>
        </div>
    );
};
