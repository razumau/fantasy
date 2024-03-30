import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();
//
// interface Tournament {
//     id: string;
//     name: string;
//     slug: string;
// }

export async function fetchTournamentBySlug(slug: string): Promise<any> {
    // Implementation depends on your backend or API
    const tournament = await prisma.tournament.findUnique({
        where: { slug }
    });
    return tournament;
}
