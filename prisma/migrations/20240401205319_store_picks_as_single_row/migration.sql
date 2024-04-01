/*
  Warnings:

  - You are about to drop the column `teamId` on the `Pick` table. All the data in the column will be lost.
  - Added the required column `teamIds` to the `Pick` table without a default value. This is not possible if the table is not empty.
  - Added the required column `version` to the `Pick` table without a default value. This is not possible if the table is not empty.

*/
-- RedefineTables
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_Pick" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "userId" INTEGER NOT NULL,
    "tournamentId" INTEGER NOT NULL,
    "teamIds" TEXT NOT NULL,
    "version" INTEGER NOT NULL,
    CONSTRAINT "Pick_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Pick_tournamentId_fkey" FOREIGN KEY ("tournamentId") REFERENCES "Tournament" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_Pick" ("id", "tournamentId", "userId") SELECT "id", "tournamentId", "userId" FROM "Pick";
DROP TABLE "Pick";
ALTER TABLE "new_Pick" RENAME TO "Pick";
CREATE UNIQUE INDEX "Pick_userId_tournamentId_key" ON "Pick"("userId", "tournamentId");
PRAGMA foreign_key_check;
PRAGMA foreign_keys=ON;
