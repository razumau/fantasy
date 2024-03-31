'use client'

import TeamsTable from "@/components/table";

type Tournament = {
    id: number;
    title: string;
}

interface Team {
    id: number;
    name: string;
    price: number;
}

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

            {/* Main Content */}
            <div className="flex flex-col md:flex-row gap-4">
                {/* Table */}
                <div className="flex-grow md:w-2/3 bg-white shadow rounded-lg p-4">
                    <h2 className="font-semibold text-xl mb-4">Table Title</h2>
                    <TeamsTable teams={teams} maxTeams={5} maxPrice={150}></TeamsTable>
                </div>

                {/* Information Box */}
                <div className="md:w-1/3 bg-white shadow rounded-lg p-4">
                    <h2 className="font-semibold text-xl mb-4">Information Box</h2>
                    {/* Dynamic content goes here */}
                    <p className="mb-2">This is a paragraph with some information.</p>
                    <p className="mb-2">Here's another paragraph with additional information.</p>
                    {/* Add or remove paragraphs based on user actions */}
                </div>
            </div>
        </div>
    );
};
