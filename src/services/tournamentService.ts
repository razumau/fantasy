import prisma from '@/lib/prisma'

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
