import { PrismaClient } from '@prisma/client'

declare global {
  var prisma: PrismaClient | undefined
}

const prisma = global.prisma || new PrismaClient()

if (process.env.NODE_ENV === 'development') global.prisma = prisma

prisma.$queryRaw`PRAGMA journal_mode = WAL;`;
prisma.$queryRaw`PRAGMA synchronous = NORMAL;`;
prisma.$queryRaw`PRAGMA busy_timeout = 5000;`;

export default prisma
