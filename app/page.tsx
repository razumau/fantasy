import { auth, clerkClient, UserButton } from "@clerk/nextjs";
import prisma from '@/lib/prisma'

export default async function Home() {
    const { userId } = auth();

    if (!userId) {
        return (
            <div className="h-screen">
                <UserButton />
            </div>
        )
    }

    const clerkUser = await clerkClient.users.getUser(userId);
    console.log(clerkUser);

    const dbUser = await prisma.user.findUnique({
        where: {
            clerkId: userId,
        },
    });

    const name = clerkUser.username || `${clerkUser.firstName} ${clerkUser.lastName}`

    if (!dbUser) {
        const newUser = await prisma.user.create({
            data: {
                clerkId: userId,
                name: name
            },
        });

        console.log(newUser);
    }

    return (
        <h1 className="text-3xl font-semibold text-black">
            👋 Hi, {name || `Stranger`}
        </h1>
    )
}
