export interface Tournament {
    id: number,
    title: string,
    maxTeams: number,
    maxPrice: number,
    deadline: Date,
    isOpen: boolean,
    slug: string,
    spreadsheetUrl?: string | null,
    teamColumnName?: string | null,
    resultColumnName?: string | null,
}

export interface Team {
    id: number;
    name: string;
    price: number;
    points: number;
}

export interface Picks {
    teams: Team[];
    version: number;
    totalSelectedPrice: number;
}
