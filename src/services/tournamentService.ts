import prisma from '@/lib/prisma'
//
// interface Tournament {
//     id: string;
//     name: string;
//     slug: string;
// }

export async function fetchTournamentBySlug(slug: string) {
    return prisma.tournament.findUnique({
        where: { slug },
        select: {
            title: true,
            id: true
        }
    });
}

export async function fetchTeamsForTournament(tournamentId: number) {
    return prisma.team.findMany({
        where: {tournamentId}
    });
}
