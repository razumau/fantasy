'use server'

import prisma from '@/lib/prisma';
import { fetchOrCreateUser } from '@/src/services/userService'
import { updateIdealPick } from "@/src/services/resultsService";

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

type TournamentDetails = Omit<Tournament, 'teams'> & {
    title: string;
}

type ParsedTeam = {
    name: string;
    price: number;
    points: number;
}


export async function updateTournament(tournament: TournamentDetails, teamsStr: string) {
    await prisma.tournament.update({
        where: {
            id: tournament.id,
        },
        data: {
            title: tournament.title,
            deadline: tournament.deadline,
            maxTeams: tournament.maxTeams,
            maxPrice: tournament.maxPrice,
        }
    })
    const teams = parseTeams(teamsStr);
    for (const team of teams) {
        const existingTeam = await prisma.team.findFirst({
            where: {
                tournamentId: tournament.id,
                name: team.name
            }
        });
        if (existingTeam) {
            await prisma.team.update({
                where: {id: existingTeam.id},
                data: {
                    price: team.price,
                    points: team.points,
                }
            })
        } else {
            await prisma.team.create({
                data: {
                    tournamentId: tournament.id,
                    name: team.name,
                    price: team.price,
                    points: team.points,
                }
            })
        }
    }
    await updateIdealPick(tournament.id);
}

function parseTeams(teamsStr: string): ParsedTeam[] {
    const lines = teamsStr.trim().split("\n");
    return lines.map((line: string) => {
        const parts = line.trim().split(" ");
        if (parts.length < 3) {
            throw new Error("Invalid line format: " + line);
        }

        const price = parseInt(parts[parts.length - 2]);
        const points = parseInt(parts[parts.length - 1]);
        const name = parts.slice(0, -2).join(" ");
        return { name, price, points }
    });
}

