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
}

export type Tournament = {
    slug: string;
    title: string;
}
