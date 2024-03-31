'use server'

import prisma from '@/lib/prisma'

export async function savePicks(teams) {
    console.log(teams);
    return {message: "saved"}
}
