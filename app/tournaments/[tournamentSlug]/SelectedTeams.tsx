import { Team } from './types'
import { Card, CardHeader, CardBody, CardFooter, Text, List, ListItem } from '@chakra-ui/react'

export default function SelectedTeams({ teams }: Team[]) {
    const teamsList = teams.map(team =>
        <ListItem key={team.id}>
            <Text>{team.name} ({team.price})</Text>
        </ListItem>
    )
    const pricesSum = teams.reduce((sum, team) => sum + team.price, 0);
    return (
        <Card>
            <CardBody>
                <CardHeader>Spent {pricesSum} points</CardHeader>
                <List spacing={3}>{teamsList}</List>
            </CardBody>
        </Card>
)
}
