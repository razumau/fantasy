import { PrismaClient } from '@prisma/client'
const prisma = new PrismaClient()

async function main() {
    const user = await prisma.user.upsert({
        where: { clerkId: 'user_2e67b28OTBXFrAy8H3p6vRYlUQe' },
        update: {},
        create: {
            clerkId: 'user_2e67b28OTBXFrAy8H3p6vRYlUQe',
            name: 'Jury Razumau',
            isAdmin: true,
        },
    });

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
    })
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
