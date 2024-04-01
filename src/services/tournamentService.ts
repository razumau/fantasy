import prisma from '@/lib/prisma'
import {auth} from "@clerk/nextjs";
import {fetchOrCreateUser} from "@/src/services/userService";

export async function fetchTournamentBySlug(slug: string) {
    return prisma.tournament.findUnique({
        where: { slug },
        select: {
            title: true,
            id: true,
            maxPrice: true,
            maxTeams: true
        }
    });
}

export async function fetchTeamsForTournament(tournamentId: number) {
    return prisma.team.findMany({
        where: {tournamentId}
    });
}

export async function fetchPicks(tournamentId: number) {
    const clerkUserId = auth().userId;
    if (!clerkUserId) {
        throw new Error('User not authenticated');
    }

    const userId = await fetchOrCreateUser(clerkUserId);
    const picks = await prisma.pick.findUnique({
        where: { userId_tournamentId: { userId, tournamentId } },
        select: { teamIds: true, version: true }
    });

    if (!picks) {
        return [];
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