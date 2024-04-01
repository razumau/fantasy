import { Team } from './types'

export default function SelectedTeams({ teams }: Team[]) {
    const teamsList = teams.map(team =>
        <li key={team.id}>
            <p>{team.name} ({team.price})</p>
        </li>
    )
    return (
        <ul>{teamsList}</ul>
    )
}
