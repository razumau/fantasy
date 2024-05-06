import React from "react";
import {List, ListItem, Text, Card, CardBody} from '@chakra-ui/react'
import {IdealPick} from "@/app/tournaments/[tournamentSlug]/results/types";

type IdealPickProps = {
    idealPick: IdealPick
}

export default function IdealPickBox({ idealPick }: IdealPickProps) {
    if (!idealPick || idealPick.teams.length === 0) {
        return null;
    }

    const teamsList = idealPick.teams.map(team => {
        const teamLine = `${team.name} (${team.price}) — ${team.points}`
        return <ListItem key={team.id}>{teamLine}</ListItem>;
    });

    return (
        <Card mt={4}>
            <CardBody>
            <Text pb={4}>The maximum possible score was {idealPick.points} points. You could get there with these teams:</Text>
            <List spacing={2}>{teamsList}</List>
        </CardBody>
        </Card>
    )
}
