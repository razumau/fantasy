import { Team } from './types'
import {Text, List, ListItem, Progress} from '@chakra-ui/react'

interface SelectedTeams {
    teams: Team[];
    maxPrice: number;
    isOpen: boolean;
}

export default function SelectedTeams({ teams, maxPrice, isOpen }: SelectedTeams) {
    if (!isOpen && !teams.length) {
        return (<></>);
    }

    const teamsList = teams.map(team =>
        <ListItem key={team.id}>
            <Text>{team.name} ({team.price})</Text>
        </ListItem>
    )
    const pricesSum = teams.reduce((sum, team) => sum + team.price, 0);
    return (
        <>
            <Text pb={4}>Spent {pricesSum} out of {maxPrice} points</Text>
            <Progress value={pricesSum * 100 / maxPrice}/>
            <List pt={4} spacing={3}>
                {teamsList}
            </List>
        </>
    );
}
