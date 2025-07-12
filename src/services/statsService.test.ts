import { fetchTeamStats, fetchTournamentMetrics } from './statsService';
import prisma from '@/lib/prisma';

describe('Stats Service', () => {
    let testTournament: any;

    beforeAll(async () => {
        testTournament = await prisma.tournament.findUnique({
            where: { slug: 'test-2' }
        });
        
        if (!testTournament) {
            throw new Error('test-2 tournament not found. Make sure to run seed first.');
        }
    });

    afterAll(async () => {
        await prisma.$disconnect();
    });

    describe('fetchTeamStats', () => {
        test('should return team stats with correct differences', async () => {
            const stats = await fetchTeamStats(testTournament.id);
            
            expect(stats.length).toBeGreaterThan(0);

            const team1 = stats.find(s => s.name === 'Team 1');
            expect(team1).toBeDefined();
            expect(team1!.price).toBe(50);
            expect(team1!.points).toBe(47);
            expect(team1!.difference).toBe(-3);

            stats.forEach(team => {
                expect(team.difference).toBe(team.points - team.price);
            });
        });

        test('should order teams by points descending, then name ascending', async () => {
            const stats = await fetchTeamStats(testTournament.id);

            for (let i = 0; i < stats.length - 1; i++) {
                expect(stats[i].points).toBeGreaterThanOrEqual(stats[i + 1].points);
            }
        });
    });

    describe('fetchTournamentMetrics', () => {
        test('should calculate correct tournament metrics', async () => {
            const metrics = await fetchTournamentMetrics(testTournament.id);
            expect(metrics.difficultyBias).toBeCloseTo(-0.7, 2);
            expect(metrics.accuracy).toBeCloseTo(64.7, 2);
        });

        test('should handle tournaments with no results', async () => {
            const emptyTournament = await prisma.tournament.create({
                data: {
                    slug: 'test-empty-temp',
                    title: 'Empty Test',
                    deadline: new Date('2025-01-01'),
                    maxPrice: 100,
                    maxTeams: 5
                }
            });

            const metrics = await fetchTournamentMetrics(emptyTournament.id);
            expect(metrics.accuracy).toBe(0);
            expect(metrics.difficultyBias).toBe(0);

            await prisma.tournament.delete({
                where: { id: emptyTournament.id }
            });
        });
    });
});
