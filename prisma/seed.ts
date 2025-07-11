import { PrismaClient, Tournament } from '@prisma/client'
const prisma = new PrismaClient()

async function createUser() {
    await prisma.user.upsert({
        where: { clerkId: 'user_2e67b28OTBXFrAy8H3p6vRYlUQe' },
        update: {},
        create: {
            clerkId: 'user_2e67b28OTBXFrAy8H3p6vRYlUQe',
            name: 'Jury Razumau',
            isAdmin: true,
        },
    });
}

async function createTournaments() {
    const testOne = await prisma.tournament.upsert({
        where: { slug: "test-1" },
        update: {},
        create: {
            slug: "test-1",
            title: "Test tournament 2124",
            deadline: new Date("2124-01-01T10:00:00.000Z"),
            maxPrice: 100,
            maxTeams: 3,
        }
    })

    const testTwo = await prisma.tournament.upsert({
        where: { slug: "test-2" },
        update: {},
        create: {
            slug: "test-2",
            title: "Test tournament 2023",
            deadline: new Date("2023-01-01T10:00:00.000Z"),
            maxPrice: 100,
            maxTeams: 3,
        }
    });

    return [testOne, testTwo];
}

async function createTeams(tournamentId: number, withPoints: boolean = false) {
    const teams: [string, number][] = [
        ["Team 1", 50],
        ["Team 2", 40],
        ["Team 3", 40],
        ["Team 4", 30],
        ["Team 5", 30],
        ["Team 6", 30],
        ["Team 7", 20],
        ["Team 8", 20],
        ["Team 9", 15],
        ["Team 10", 15],
        ["Team 11", 15],
        ["Team 12", 15],
        ["Team 13", 15],
    ]
    for (let i = 0; i < teams.length; i++) {
        const [name, price] = teams[i];
        const teamNumber = i + 1;
        let points = 0;
        
        if (withPoints) {
            points = teamNumber % 2 === 0 ? price + 2 : price - 3;
        }

        const team = await prisma.team.findFirst({ where: { tournamentId, name, price, points} });

        if (!team) {
            await prisma.team.create({ data: { tournamentId, name, price, points } })
        }
    }
}

async function main() {
    await createUser();
    const [testOne, testTwo] = await createTournaments();
    await createTeams(testOne.id, false);
    await createTeams(testTwo.id, true);
}

main()
    .then(async () => {
        await prisma.$disconnect()
    })
    .catch(async (e) => {
        console.error(e)
        await prisma.$disconnect()
        process.exit(1)
    })
