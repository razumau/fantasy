export type Team = {
    name: string;
    price: number;
    points: number;
    id: number;
}

export type Result = {
    username: string;
    userId: number;
    teams: Team[];
    points: number;
    rank: number;
}

export type IdealPick = {
    teams: Team[];
    points: number;
}

export type Tournament = {
    slug: string;
    title: string;
}
