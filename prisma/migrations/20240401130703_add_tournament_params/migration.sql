-- RedefineTables
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_Tournament" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "start" DATETIME NOT NULL,
    "finish" DATETIME NOT NULL,
    "title" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "maxTeams" INTEGER NOT NULL DEFAULT 5,
    "maxPrice" INTEGER NOT NULL DEFAULT 150,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL
);
INSERT INTO "new_Tournament" ("createdAt", "finish", "id", "slug", "start", "title", "updatedAt") SELECT "createdAt", "finish", "id", "slug", "start", "title", "updatedAt" FROM "Tournament";
DROP TABLE "Tournament";
ALTER TABLE "new_Tournament" RENAME TO "Tournament";
CREATE UNIQUE INDEX "Tournament_slug_key" ON "Tournament"("slug");
PRAGMA foreign_key_check;
PRAGMA foreign_keys=ON;
