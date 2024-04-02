import { Team } from './types'

export default function SelectedTeams({ teams }: Team[]) {
    const teamsList = teams.map(team =>
        <li key={team.id}>
            <p>{team.name} ({team.price})</p>
        </li>
    )
    const pricesSum = teams.reduce((sum, team) => sum + team.price, 0);
    return (
        <><p>Spent {pricesSum} points</p>
            <ul>{teamsList}</ul>
        </>
    )
}
