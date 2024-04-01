'use server'

import { auth } from "@clerk/nextjs";
import prisma from '@/lib/prisma';

type Team = {
    id: number;
    price: number;
}

type Tournament = {
    id: number;
    start: object;
    maxTeams: number;
    maxPrice: number;
    teams: Team[];
}

type PicksInput = {
    teamIds: number[];
    tournamentId: number;
    version: number;
}

export async function savePicks({ teamIds, tournamentId }: PicksInput) {
    const clerkUser = auth();
    if (!clerkUser?.userId) {
        throw new Error('User not authenticated');
    }

    const userId = await fetchOrCreateUser(clerkUser);
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
            userId_tournamentId: { userId, tournamentId }
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
            version: { increment: 1 },
            teamIds: JSON.stringify(teamIds)
        }
    })

    return { message: "saved" }
}

async function fetchOrCreateUser(clerkUser) {
    const user = await prisma.user.findUnique({
        where: { clerkId: clerkUser.userId },
        select: { id: true }
    });

    if (user) {
        return user.id;
    }

    const name = clerkUser.username || `${clerkUser.firstName} ${clerkUser.lastName}`;
    const newUser = await prisma.user.create({
        data: {
            clerkId: userId,
            name: name
        },
    });
    return newUser.id;
}

async function fetchTournament(tournamentId: number) {
    return prisma.tournament.findUnique({
        where: {id: tournamentId},
        select: {
            id: true,
            start: true,
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
    return new Date() >= tournament.start;
}


