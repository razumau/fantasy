import prisma from '@/lib/prisma'

export interface TeamStats {
    id: number;
    name: string;
    price: number;
    points: number;
    difference: number;
}

export interface TournamentMetrics {
    accuracy: number;
    difficultyBias: number;
}

export interface TeamResult {
    teamId: number;
    predicted: number;
    actual: number;
}

function calculateTournamentMetrics(
    results: TeamResult[],
    maxPoints: number
): TournamentMetrics {
    if (results.length === 0) {
        return { accuracy: 0, difficultyBias: 0 };
    }

    const biases = results.map(r => r.actual - r.predicted);
    const difficultyBias = biases.reduce((sum, b) => sum + b, 0) / results.length;
    
    const correctedErrors = results.map(r =>
        Math.abs(r.actual - r.predicted - difficultyBias)
    );
    const mae = correctedErrors.reduce((sum, e) => sum + e, 0) / results.length;
    
    const maxReasonableError = maxPoints * 0.15;
    const accuracy = Math.max(0, 100 * (1 - mae / maxReasonableError));
    
    return {
        accuracy: Math.round(accuracy * 10) / 10,
        difficultyBias: Math.round(difficultyBias * 10) / 10
    };
}

export async function fetchTeamStats(tournamentId: number): Promise<TeamStats[]> {
    const teams = await prisma.team.findMany({
        where: { tournamentId },
        orderBy: [{ points: 'desc' }, { name: 'asc' }]
    });

    return teams.map(team => ({
        id: team.id,
        name: team.name,
        price: team.price,
        points: team.points,
        difference: team.points - team.price
    }));
}

export async function fetchTournamentMetrics(tournamentId: number): Promise<TournamentMetrics> {
    const teams = await prisma.team.findMany({
        where: { tournamentId },
        select: { id: true, price: true, points: true }
    });

    if (teams.length === 0) {
        return { accuracy: 0, difficultyBias: 0 };
    }

    const results: TeamResult[] = teams.map(team => ({
        teamId: team.id,
        predicted: team.price,
        actual: team.points
    }));

    const maxPoints = Math.max(...teams.map(t => t.points));
    
    return calculateTournamentMetrics(results, maxPoints);
}
