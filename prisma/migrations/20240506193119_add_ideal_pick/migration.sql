-- CreateTable
CREATE TABLE "IdealPick" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "tournamentId" INTEGER NOT NULL,
    "teamIds" TEXT NOT NULL,
    "points" INTEGER NOT NULL,
    CONSTRAINT "IdealPick_tournamentId_fkey" FOREIGN KEY ("tournamentId") REFERENCES "Tournament" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateIndex
CREATE UNIQUE INDEX "IdealPick_tournamentId_key" ON "IdealPick"("tournamentId");
