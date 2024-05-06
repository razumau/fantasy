import prisma from "@/lib/prisma";
import {Result, IdealPick} from "@/app/tournaments/[tournamentSlug]/results/types";
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

export async function fetchIdealPick(tournamentId: number): Promise<IdealPick> {
    const tournament = await prisma.tournament.findUnique({
        where: { id: tournamentId },
        select: { maxTeams: true, maxPrice: true, deadline: true }
    });

    if (!tournament || tournament.deadline > new Date()) {
        return { teams: [], points: 0 };
    }

    const teamsMap = await fetchTeamsAsMap(tournamentId);

    const existingPick = await prisma.idealPick.findFirst({
        where: { tournamentId },
        select: { teamIds: true, points: true }
    });

    if (!existingPick) {
        const pick = calculateIdealPick(teamsMap, tournament.maxTeams, tournament.maxPrice);
        await saveIdealPick(tournamentId, pick);
        return pick;
    }

    return {
        teams: filterTeamsForPick(JSON.parse(existingPick.teamIds), teamsMap),
        points: existingPick.points
    }
}

function calculateIdealPick(teamsMap: TeamsMap, maxTeams: number, maxPrice: number): IdealPick {
    const teams = Array.from(teamsMap.values());
    const allCombinations = generateCombinations(teams, maxTeams);
    let maxPoints = 0;
    let bestCombination: Team[] = [];

    for (const combination of allCombinations) {
        const totalPrice = combination.reduce((sum, team) => sum + team.price, 0);
        if (totalPrice <= maxPrice) {
            const totalPoints = combination.reduce((sum, team) => sum + team.points, 0);
            if (totalPoints > maxPoints) {
                maxPoints = totalPoints;
                bestCombination = combination;
            }
        }
    }

    return {
        teams: bestCombination,
        points: maxPoints
    };
}

function generateCombinations(teams: Team[], maxTeams: number): Team[][] {
    if (maxTeams === 0) {
        return [[]];
    }
    let combinations: Team[][] = [];
    for (let i = 0; i < teams.length; i++) {
        const team = teams[i];
        const remaining = teams.slice(i + 1);
        const remainingCombinations = generateCombinations(remaining, maxTeams - 1);
        const teamCombinations = remainingCombinations.map(combination => [team, ...combination]);
        combinations = [...combinations, ...teamCombinations];
    }

    return combinations;
}

async function saveIdealPick(tournamentId: number, pick: IdealPick) {
    await prisma.idealPick.create({
        data: {
            tournamentId,
            teamIds: JSON.stringify(pick.teams.map(team => team.id)),
            points: pick.points
        }
    });
}
