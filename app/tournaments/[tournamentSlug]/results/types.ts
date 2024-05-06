export type Result = {
    username: string;
    userId: number;
    teams: {
        id: number;
        name: string;
        price: number;
        points: number;
    }[];
    points: number;
    rank: number;
}

export type Tournament = {
    slug: string;
    title: string;
}
