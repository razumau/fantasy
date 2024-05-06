import prisma from "@/lib/prisma";
import {Result} from "@/app/tournaments/[tournamentSlug]/results/types";
type TeamsMap = Map<number, {name: string, points: number, price: number, id: number}>;
type Pick = {
    teamIds: number[];
    username: string;
    userId: number;
}

type Team = {
    name: string;
    price: number;
    points: number;
    id: number;
}

export async function fetchTournamentResults(tournamentId: number) {
    const picks = await fetchPicks(tournamentId);
    const teams = await fetchTeamsAsMap(tournamentId);

    const results = picks
        .map(({ username, userId, teamIds }) => {
            const teamsForPick = filterTeamsForPick(teamIds, teams);
            const points = teamsForPick.reduce((sum, team) => sum + team.points, 0);
            return {
                username,
                userId,
                teams: teamsForPick,
                points,
            }
        })
        .sort((resultA, resultB) => resultB.points - resultA.points);
    return addRanks(results);
}

function addRanks(results: Omit<Result, 'rank'>[]): Result[] {
    let rank = 0, prevPoints = -1;
    return results.map((result, index) => {
        if (result.points !== prevPoints) {
            rank = index + 1;
        }
        prevPoints = result.points;
        return {...result, rank};
    });
}

async function fetchPicks(tournamentId: number): Promise<Pick[]> {
    const picks = await prisma.pick.findMany({
        where: {
            tournamentId,
            NOT: {
                teamIds: '[]'
            }
        },
        select: {
            teamIds: true,
            user: { select: { name: true, id: true } }
        }
    });

    return picks.map(pick => ({
        teamIds: JSON.parse(pick.teamIds),
        username: pick.user.name,
        userId: pick.user.id,
    }));
}

async function fetchTeamsAsMap(tournamentId: number): Promise<TeamsMap> {
    const teamsList = await prisma.team.findMany({
        where: { tournamentId },
        select: { name: true, price: true, points: true, id: true }
    });
    const teams: Map<number, {name: string, points: number, price: number, id: number}> = new Map();
    teamsList.forEach(team => { teams.set(team.id, team) });
    return teams;
}

function filterTeamsForPick(teamIds: number[], teamsMap: TeamsMap): Team[] {
    return teamIds.map(id => {
        const team = teamsMap.get(id);
        if (!team) {
            throw new Error(`A pick has been made for a non-existent team ${id}`);
        }
        return team;
    }).sort((teamA, teamB) => (teamB.points * 1000 + teamB.price) - (teamA.points * 1000 + teamA.price));
}
