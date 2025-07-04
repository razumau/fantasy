import prisma from '@/lib/prisma'
import {fetchOrCreateUser} from "@/src/services/userService";

export async function fetchTournamentBySlug(slug: string) {
    const tournament = await prisma.tournament.findUnique({
        where: { slug },
        select: {
            title: true,
            id: true,
            maxPrice: true,
            maxTeams: true,
            deadline: true,
            spreadsheetUrl: true,
            teamColumnName: true,
            resultColumnName: true,
        }
    });

    if (!tournament) { return null; }

    return {...tournament, isOpen: (new Date() < tournament.deadline), slug };
}

export async function fetchOrCreateTournament(slug: string) {
    return prisma.tournament.upsert({
        where: {slug},
        update: {},
        create: {
            slug,
            title: "",
            deadline: new Date("2100-01-01T00:00:00.000Z"),
            maxPrice: 200,
            maxTeams: 5,
        }
    })
}

export async function fetchTeamsForTournament(tournamentId: number) {
    return prisma.team.findMany({
        where: {tournamentId},
        orderBy: [ { price: 'desc' }, { name: 'asc' } ]
    });
}

export async function fetchPicks(tournamentId: number) {
    const userId = await fetchOrCreateUser();
    const picks = await prisma.pick.findUnique({
        where: { userId_tournamentId: { userId, tournamentId } },
        select: { teamIds: true, version: true }
    });

    if (!picks) {
        return {
            teams: [],
            version: 0,
            totalSelectedPrice: 0
        };
    }

    const teamIds = JSON.parse(picks.teamIds);
    const teams = await prisma.team.findMany({
        where: { id: { in: teamIds } }
    });
    const totalSelectedPrice = teams.reduce((sum, team) => sum + team.price, 0);

    return {
        teams,
        version: picks.version,
        totalSelectedPrice
    }
}

export async function fetchPopularTeamsForTournament(tournamentId: number) {
    const picks = await prisma.pick.findMany({
        where: {
            tournamentId,
            NOT: {
                teamIds: "[]",
            }
        },
        select: {teamIds: true}
    });
    const teams = await prisma.team.findMany({
        where: { tournamentId },
        select: { name: true, price: true, id: true }
    });

    const counter = buildPopularityCounter(picks);
    const teamsByPopularity = teams.map(team => {
        const count = counter.get(team.id) || 0;
        const percentage = (picks.length ? count * 100 / picks.length : 0).toFixed(1);
        return {
            ...team,
            count,
            percentage,
        }
    }).sort((teamA, teamB) => teamB.count - teamA.count);

    return { teamsByPopularity, usersWithPickCount: picks.length }
}

function buildPopularityCounter(picks: { teamIds: string }[]): Map<number, number> {
    const counter: Map<number, number> = new Map();

    picks.map(pick => JSON.parse(pick.teamIds))
        .flat()
        .reduce((counter, teamId) => {
            const newCount = counter.has(teamId)? counter.get(teamId) + 1 : 1;
            counter.set(teamId, newCount);
            return counter;
        }, counter);

    return counter;
}

export async function fetchOpenTournaments() {
    return prisma.tournament.findMany({
        where: {
            deadline: {
                gt: new Date()
            },
            title: {
                not: {
                    startsWith: 'Test'
                }
            }
        },
        select: {
            title: true,
            slug: true,
            deadline: true
        },
        orderBy: {
            deadline: 'asc'
        }
    });
}

export async function fetchClosedTournaments() {
    return prisma.tournament.findMany({
        where: {
            deadline: {
                lte: new Date()
            },
            title: {
                not: {
                    startsWith: 'Test'
                }
            }
        },
        select: {
            title: true,
            slug: true,
            deadline: true
        },
        orderBy: {
            deadline: 'desc'
        }
    });
}
