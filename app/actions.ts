'use server'

import prisma from '@/lib/prisma';
import { fetchOrCreateUser } from '@/src/services/userService'

type Team = {
    id: number;
    price: number;
}

type Tournament = {
    id: number;
    deadline: object;
    maxTeams: number;
    maxPrice: number;
    teams: Team[];
}

type PicksInput = {
    teamIds: number[];
    tournamentId: number;
    version: number;
}

export async function savePicks({ teamIds, tournamentId, version }: PicksInput) {
    const userId = await fetchOrCreateUser();
    const tournament = await fetchTournament(tournamentId);

    if (!tournament) {
        throw new Error('No tournament for this ID');
    }

    if (isTournamentClosed(tournament)) {
        throw new Error('Tournament closed');
    }

    if (arePicksInvalid(teamIds, tournament)) {
        throw new Error('Invalid picks');
    }

    await prisma.pick.upsert({
        where: {
            userId_tournamentId: { userId, tournamentId },
            version: { lt: version }
        },
        create: {
            userId,
            tournamentId,
            version: 0,
            teamIds: JSON.stringify(teamIds)
        },
        update: {
            userId,
            tournamentId,
            version,
            teamIds: JSON.stringify(teamIds)
        }
    })

    return { message: "picks saved" }
}



async function fetchTournament(tournamentId: number) {
    return prisma.tournament.findUnique({
        where: {id: tournamentId},
        select: {
            id: true,
            deadline: true,
            maxTeams: true,
            maxPrice: true,
            teams: {
                select: {
                    id: true,
                    price: true,
                }
            }
        }
    });
}

function arePicksInvalid(teamIds: number[], tournament: Tournament): boolean {
    if (teamIds.length > tournament.maxTeams) {
        return false;
    }

    const pricesSum = tournament.teams
        .filter(team => teamIds.includes(team.id))
        .map(team => team.price)
        .reduce((sum, price) => sum + price, 0);

    return pricesSum > tournament.maxPrice;
}

function isTournamentClosed(tournament: Tournament): boolean {
    return new Date() >= tournament.deadline;
}


