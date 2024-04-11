import prisma from '@/lib/prisma'
import {currentUser} from "@clerk/nextjs";

export async function fetchOrCreateUser() {
    const clerkUser = await fetchClerkUser();
    const name = clerkUser.username || `${clerkUser.firstName} ${clerkUser.lastName}`;
    const user = await prisma.user.findUnique({
        where: { clerkId: clerkUser.id },
        select: { id: true, name: true }
    });

    if (user) {
        if (user.name !== name) {
            await updateUser(clerkUser.id, name);
        }
        return user.id;
    }
    return await createUser(clerkUser.id, name);
}

async function createUser(clerkId: string, name: string) {
    const newUser = await prisma.user.create({
        data: { clerkId, name },
    });
    return newUser.id;
}

async function fetchClerkUser() {
    const clerkUser = await currentUser();
    if (!clerkUser) {
        throw new Error('User not authenticated');
    }
    return clerkUser;
}

async function updateUser(clerkId: string, name: string) {
    const user = await prisma.user.update({
        where: { clerkId },
        data: { name },
    });

    return user.id;
}