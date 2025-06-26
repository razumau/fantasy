'use server'

import prisma from '@/lib/prisma';
import { fetchOrCreateUser } from '@/src/services/userService'
import { updateIdealPick } from "@/src/services/resultsService";
import * as XLSX from 'xlsx';

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
    spreadsheetUrl?: string | null;
    teamColumnName?: string | null;
    resultColumnName?: string | null;
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
            spreadsheetUrl: tournament.spreadsheetUrl,
            teamColumnName: tournament.teamColumnName,
            resultColumnName: tournament.resultColumnName,
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

export async function fetchResults(tournamentId: number) {
    const tournament = await prisma.tournament.findUnique({
        where: { id: tournamentId },
        select: {
            spreadsheetUrl: true,
            teamColumnName: true,
            resultColumnName: true,
            teams: {
                select: {
                    id: true,
                    name: true
                }
            }
        }
    });

    if (!tournament?.spreadsheetUrl || !tournament.teamColumnName || !tournament.resultColumnName) {
        throw new Error('Spreadsheet not configured for this tournament');
    }

    try {
        const response = await fetch(tournament.spreadsheetUrl);
        if (!response.ok) {
            throw new Error('Failed to fetch spreadsheet');
        }

        const arrayBuffer = await response.arrayBuffer();
        const workbook = XLSX.read(arrayBuffer, { type: 'array' });
        const worksheetName = workbook.SheetNames[0];
        const worksheet = workbook.Sheets[worksheetName];
        const data = XLSX.utils.sheet_to_json(worksheet);

        const headerRow = data[0] as Record<string, any>;
        const teamColumn = mapColumnNameToSheetLetter(tournament.teamColumnName, headerRow);
        const resultColumn = mapColumnNameToSheetLetter(tournament.resultColumnName, headerRow);

        if (!teamColumn || !resultColumn) { throw new Error('Could not find team or result column in spreadsheet') }

        let updatedCount = 0;
        for (const row of data.slice(1)) {
            const rowData = row as Record<string, any>;
            const teamName = rowData[teamColumn];
            const points = rowData[resultColumn];
            if (!teamName || !points) { continue }

            const matchingTeam = tournament.teams.find(team =>
                team.name.toLowerCase() === teamName.toString().toLowerCase()
            );
            if (!matchingTeam) { continue }

            await prisma.team.update({
                where: { id: matchingTeam.id },
                data: { points }
            });
            updatedCount++;
        }

        await updateIdealPick(tournamentId);
        
        return { message: `Updated ${updatedCount} teams with results from spreadsheet` };
    } catch (error) {
        console.error('Error fetching results:', error);
        throw new Error('Failed to process spreadsheet: ' + (error instanceof Error ? error.message : 'Unknown error'));
    }
}

function mapColumnNameToSheetLetter(columnName: string, headerRow: Record<string, any>): string | undefined {
    return Object.keys(headerRow).find(k => headerRow[k] === columnName);
}

type CreateTournamentDetails = {
    title: string;
    slug: string;
    deadline: Date;
    maxTeams: number;
    maxPrice: number;
    spreadsheetUrl?: string | null;
    teamColumnName?: string | null;
    resultColumnName?: string | null;
}

export async function createTournament(tournamentDetails: CreateTournamentDetails, teamsStr: string) {
    const tournament = await prisma.tournament.create({
        data: {
            title: tournamentDetails.title,
            slug: tournamentDetails.slug,
            deadline: tournamentDetails.deadline,
            maxTeams: tournamentDetails.maxTeams,
            maxPrice: tournamentDetails.maxPrice,
            spreadsheetUrl: tournamentDetails.spreadsheetUrl,
            teamColumnName: tournamentDetails.teamColumnName,
            resultColumnName: tournamentDetails.resultColumnName,
        }
    });

    const teams = parseTeamsForCreate(teamsStr);
    for (const team of teams) {
        await prisma.team.create({
            data: {
                tournamentId: tournament.id,
                name: team.name,
                price: team.price,
                points: 0,
            }
        });
    }

    return tournament;
}

function parseTeamsForCreate(teamsStr: string): { name: string; price: number }[] {
    const lines = teamsStr.trim().split("\n");
    return lines.map((line: string) => {
        const parts = line.trim().split(" ");
        if (parts.length < 2) {
            throw new Error("Invalid line format: " + line + ". Expected format: 'TeamName Price'");
        }

        const price = parseInt(parts[parts.length - 1]);
        if (isNaN(price)) {
            throw new Error("Invalid price in line: " + line);
        }

        const name = parts.slice(0, -1).join(" ");
        return { name, price };
    });
}
