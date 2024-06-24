import { calculateIdealPick } from './resultsService';
import {Team} from "@/app/tournaments/[tournamentSlug]/types";

function buildTeam(price: number, points: number): Team {
    const id = Math.floor(Math.random() * 1000);
    return { name: `Team ${id}`, points, price, id };
}

test('ideal pick for a minimal list', () => {
    const teams = [
        buildTeam(10, 10),
        buildTeam(20, 20),
        buildTeam(30, 30),
        buildTeam(40, 40),
    ];

    expect(calculateIdealPick(teams, 4, 100).points).toEqual(100);
    expect(calculateIdealPick(teams, 3, 100).points).toEqual(90);
});

test('ideal pick for a full list', () => {
    const teams = [
        buildTeam(10, 10),
        buildTeam(10, 15),
        buildTeam(20, 18),
        buildTeam(20, 22),
        buildTeam(20, 32),
        buildTeam(25, 32),
        buildTeam(25, 32),
        buildTeam(35, 32),
        buildTeam(35, 35),
        buildTeam(35, 43),
        buildTeam(40, 32),
        buildTeam(40, 43),
        buildTeam(40, 43),
        buildTeam(45, 43),
        buildTeam(45, 44),
        buildTeam(45, 45),
        buildTeam(50, 34),
        buildTeam(50, 52),
        buildTeam(50, 62),
        buildTeam(55, 50),
        buildTeam(55, 53),
        buildTeam(60, 60),
        buildTeam(60, 61),
    ];

    expect(calculateIdealPick(teams, 4, 150).points).toEqual(182);
    expect(calculateIdealPick(teams, 4, 180).points).toEqual(207);
    expect(calculateIdealPick(teams, 4, 200).points).toEqual(219);
    expect(calculateIdealPick(teams, 5, 180).points).toEqual(221);
    expect(calculateIdealPick(teams, 5, 200).points).toEqual(234);
    expect(calculateIdealPick(teams, 5, 220).points).toEqual(251);
    expect(calculateIdealPick(teams, 6, 220).points).toEqual(264);
});

test('ideal pick for an unusually long list', () => {
    const teams = [
        buildTeam(15, 9),
        buildTeam(15, 19),
        buildTeam(15, 12),
        buildTeam(15, 10),
        buildTeam(15, 20),
        buildTeam(15, 18),
        buildTeam(15, 20),
        buildTeam(15, 19),
        buildTeam(15, 10),
        buildTeam(20, 17),
        buildTeam(20, 17),
        buildTeam(20, 25),
        buildTeam(20, 26),
        buildTeam(20, 16),
        buildTeam(20, 13),
        buildTeam(20, 24),
        buildTeam(20, 26),
        buildTeam(20, 26),
        buildTeam(20, 20),
        buildTeam(25, 28),
        buildTeam(25, 25),
        buildTeam(25, 27),
        buildTeam(25, 21),
        buildTeam(25, 18),
        buildTeam(25, 27),
        buildTeam(25, 22),
        buildTeam(25, 26),
        buildTeam(30, 26),
        buildTeam(30, 34),
        buildTeam(30, 32),
        buildTeam(30, 30),
        buildTeam(30, 27),
        buildTeam(30, 28),
        buildTeam(30, 30),
        buildTeam(30, 26),
        buildTeam(35, 35),
        buildTeam(35, 30),
        buildTeam(35, 31),
        buildTeam(35, 33),
        buildTeam(35, 28),
        buildTeam(35, 37),
        buildTeam(40, 40),
        buildTeam(40, 44),
        buildTeam(40, 45),
        buildTeam(40, 41),
        buildTeam(40, 39),
        buildTeam(40, 44),
        buildTeam(40, 35),
        buildTeam(45, 38),
        buildTeam(45, 45),
        buildTeam(45, 46),
        buildTeam(45, 41),
        buildTeam(45, 46),
        buildTeam(45, 45),
        buildTeam(45, 42),
        buildTeam(50, 50),
        buildTeam(50, 45),
        buildTeam(50, 49),
        buildTeam(50, 53),
        buildTeam(50, 54),
        buildTeam(50, 52),
        buildTeam(50, 49),
        buildTeam(50, 52),
        buildTeam(50, 46),
        buildTeam(55, 49),
        buildTeam(55, 58),
        buildTeam(55, 53),
        buildTeam(55, 55),
        buildTeam(55, 58),
        buildTeam(55, 51),
        buildTeam(55, 52),
        buildTeam(55, 56),
        buildTeam(55, 54),
        buildTeam(60, 66),
        buildTeam(60, 63),
        buildTeam(60, 59),
        buildTeam(60, 64),
        buildTeam(60, 57),
        buildTeam(60, 60),
        buildTeam(60, 63),
        buildTeam(60, 61),
        buildTeam(60, 60),
    ]

    expect(calculateIdealPick(teams, 10, 360).points).toEqual(410);
    expect(calculateIdealPick(teams, 10, 420).points).toEqual(467);
});
