export interface Tournament {
    id: number;
    title: string;
    maxTeams: number;
    maxPrice: number;
}

export interface Team {
    id: number;
    name: string;
    price: number;
}

export interface Picks {
    teams: Team[];
    version: number;
    totalSelectedPrice: number;
}
