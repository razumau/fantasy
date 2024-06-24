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

});
