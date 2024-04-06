/*
  Warnings:

  - You are about to drop the column `finish` on the `Tournament` table. All the data in the column will be lost.
  - You are about to drop the column `start` on the `Tournament` table. All the data in the column will be lost.
  - Added the required column `deadline` to the `Tournament` table without a default value. This is not possible if the table is not empty.

*/
-- RedefineTables
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_Tournament" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "deadline" DATETIME NOT NULL,
    "title" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "maxTeams" INTEGER NOT NULL DEFAULT 5,
    "maxPrice" INTEGER NOT NULL DEFAULT 150,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);
INSERT INTO "new_Tournament" ("createdAt", "id", "maxPrice", "maxTeams", "slug", "title", "updatedAt") SELECT "createdAt", "id", "maxPrice", "maxTeams", "slug", "title", "updatedAt" FROM "Tournament";
DROP TABLE "Tournament";
ALTER TABLE "new_Tournament" RENAME TO "Tournament";
CREATE UNIQUE INDEX "Tournament_slug_key" ON "Tournament"("slug");
PRAGMA foreign_key_check;
PRAGMA foreign_keys=ON;
