import prisma from '@/lib/prisma'
import {auth, currentUser} from "@clerk/nextjs";

export async function fetchOrCreateUser(clerkUserId: string) {
    const user = await prisma.user.findUnique({
        where: { clerkId: clerkUserId },
        select: { id: true }
    });

    if (user) {
        return user.id;
    }
    return await createUser();
}

async function createUser() {
    const clerkUser = await currentUser();
    if (!clerkUser) {
        throw new Error('User not authenticated');
    }
    const name = clerkUser.username || `${clerkUser.firstName} ${clerkUser.lastName}`;
    const newUser = await prisma.user.create({
        data: {
            clerkId: clerkUser.id,
            name: name
        },
    });
    return newUser.id;
}