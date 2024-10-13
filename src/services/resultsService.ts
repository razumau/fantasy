import prisma from "@/lib/prisma";
import {Result, IdealPick} from "@/app/tournaments/[tournamentSlug]/results/types";
type TeamsMap = Map<number, Team>;
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

export async function fetchIdealPick(tournamentId: number): Promise<IdealPick> {
    const tournament = await prisma.tournament.findUnique({
        where: { id: tournamentId },
        select: { maxTeams: true, maxPrice: true, deadline: true }
    });

    const emptyPick = { points: 0, teams: [] };

    if (!tournament || tournament.deadline > new Date()) {
        return emptyPick;
    }

    const pick = await prisma.idealPick.findFirst({
        where: { tournamentId },
        select: { teamIds: true, points: true }
    });

    if (!pick) {
        return emptyPick;
    }

    const teamsMap = await fetchTeamsAsMap(tournamentId);

    return {
        teams: filterTeamsForPick(JSON.parse(pick.teamIds), teamsMap),
        points: pick.points
    }
}

export async function updateIdealPick(tournamentId: number): Promise<void> {
    const tournament = await prisma.tournament.findUnique({
        where: { id: tournamentId },
        select: { maxTeams: true, maxPrice: true, deadline: true }
    });

    if (!tournament || tournament.deadline > new Date()) {
        return;
    }

    const teamsMap = await fetchTeamsAsMap(tournamentId);
    const pick = calculateIdealPick(Array.from(teamsMap.values()), tournament.maxTeams, tournament.maxPrice);
    const teamIds = JSON.stringify(pick.teams.map(team => team.id));

    await prisma.idealPick.upsert({
        where: {
            tournamentId
        },
        create: {
            tournamentId,
            teamIds,
            points: pick.points
        },
        update: {
            tournamentId,
            teamIds,
            points: pick.points
        }
    });
}

export function calculateIdealPick(teams: Team[], maxTeams: number, budget: number): IdealPick {
    const n = teams.length;
    let dp: number[][] = Array(maxTeams + 1).fill(null).map(() => Array(budget + 1).fill(0));
    let selections: number[][][] = Array(maxTeams + 1).fill(null).map(() =>
        Array(budget + 1).fill(null).map(() => [])
    );

    for (let i = 0; i < n; i++) {
        for (let k = maxTeams; k > 0; k--) {
            for (let j = budget; j >= teams[i].price; j--) {
                const newPoints = dp[k-1][j - teams[i].price] + teams[i].points;
                if (newPoints > dp[k][j]) {
                    dp[k][j] = newPoints;
                    selections[k][j] = [...selections[k-1][j - teams[i].price], i];
                }
            }
        }
    }

    let maxPoints = 0;
    let selectedIndexes: number[] = [];
    for (let k = 1; k <= maxTeams; k++) {
        for (let j = 0; j <= budget; j++) {
            if (dp[k][j] > maxPoints) {
                maxPoints = dp[k][j];
                selectedIndexes = selections[k][j];
            }
        }
    }

    const selectedTeams = selectedIndexes.map(index => teams[index]);
    return { points: maxPoints, teams: selectedTeams };
}
