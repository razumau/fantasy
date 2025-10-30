import prisma from '@/lib/prisma'
import {currentUser} from "@clerk/nextjs/server";

export async function fetchOrCreateUser() {
    const clerkUser = await fetchClerkUser();
    const user = await prisma.user.findUnique({
        where: { clerkId: clerkUser.id },
        select: { id: true, name: true }
    });

    const name = clerkUser.username
        || `${clerkUser.firstName ?? ''} ${clerkUser.lastName ?? ''}`.trim()
        || clerkUser.emailAddresses[0].emailAddress;

    if (!user) {
        return await createUser(clerkUser.id, name);
    }

    if (user.name !== name) {
        await updateUser(clerkUser.id, name);
    }

    return user.id;
}

export async function fetchAdminStatus(): Promise<boolean> {
    const clerkUser = await fetchClerkUser();
    const user = await prisma.user.findUnique({
        where: { clerkId: clerkUser.id },
        select: { isAdmin: true }
    });
    if (!user) {
        return false;
    }
    return user.isAdmin;
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