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
