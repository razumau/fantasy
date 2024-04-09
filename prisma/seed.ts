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
    const tournament = await prisma.tournament.upsert({
        where: { slug: "pl-2024" },
        update: {},
        create: {
            slug: "pl-2024",
            title: "Чемпионат Польши 2024",
            deadline: new Date("2024-04-13T12:00:00.000Z"),
            maxPrice: 150,
            maxTeams: 5,
        }
    })

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

    return [tournament, testOne, testTwo];
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
    for (const [name, price] of teams) {
        const points = withPoints ? price : 0;

        const team = await prisma.team.findFirst({ where: { tournamentId, name, price, points} });

        if (!team) {
            await prisma.team.create({ data: { tournamentId, name, price, points } })
        }
    }
}

async function createPL2024Teams(tournamentId: number) {
    const teams: [string, number][] = [
        ["Гимназия имени Кейси Легумины", 60],
        ["Пахне чабор!", 50],
        ["Polish Space Marines", 50],
        ["4:20", 50],
        ["1067", 50],
        ["Какая собака?", 50],
        ["Szopy", 45],
        ["Гдыгда", 45],
        ["Бесславные краснолюдки", 40],
        ["Ежу понятно", 40],
        ["Самая большая лягушка", 35],
        ["WarSowiak", 35],
        ["Чай Кава Макава", 35],
        ["Гэта элементарныя рэчы", 35],
        ["Przepraszam, jestem jabłkiem", 35],
        ["С нами Б-г", 30],
        ["Zespół Kubusia Puchatka", 30],
        ["Есть желающие", 30],
        ["Хор Овец", 30],
        ["Хождение под мухой", 25],
        ["Пингвины штурмуют эскалатор", 25],
        ["Большие люди", 25],
        ["Приемлемо", 25],
        ["69/300", 20],
        ["Чуть-чуть не докрутили", 20],
        ["Твикс Пикс", 20],
        ["Нас семеро, вместе с Джимом", 15],
        ["Душный ЗОЖ", 15]
    ];
    for (const [name, price] of teams) {
        const team = await prisma.team.findFirst({ where: { tournamentId, name, price} });

        if (!team) {
            await prisma.team.create({ data: { tournamentId, name, price } })
        }
    }
}

async function main() {
    await createUser();
    const [pl, testOne, testTwo] = await createTournaments();
    await createTeams(testOne.id, false);
    await createTeams(testTwo.id, true);
    await createPL2024Teams(pl.id);
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
