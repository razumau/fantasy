'use client'

import React, { useState, FormEvent } from 'react';
import {Tournament} from "@/app/tournaments/[tournamentSlug]/types";
import { format, parseISO } from 'date-fns';
import {Box, FormControl, FormLabel, Input, Textarea, Button, VStack, Heading} from '@chakra-ui/react';
import {updateTournament} from "@/app/actions";

type EditTournamentProps = {
    tournament: Omit<Tournament, 'isOpen'>;
    teams: string;
}

export default function EditTournament({ tournament, teams }: EditTournamentProps) {
    const [title, setTitle] = useState(tournament.title);
    const [deadline, setDeadline] = useState(format(tournament.deadline, "yyyy-MM-dd'T'HH:mm"));
    const [maxTeams, setMaxTeams] = useState(tournament.maxTeams);
    const [maxPrice, setMaxPrice] = useState(tournament.maxPrice);
    const [teamsStr, setTeamsStr] = useState(teams);

    const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
        event.preventDefault();
        const deadlineDate = parseISO(deadline);
        await updateTournament({id: tournament.id, title, deadline: deadlineDate, maxTeams, maxPrice}, teamsStr);
    };

    return <>
        <Heading textAlign={'center'} mx={2}>{tournament.title}</Heading>
        <Box p={5} shadow='md' borderWidth='1px'>
            <Heading mb={6}>Edit Tournament Details</Heading>
            <form onSubmit={handleSubmit}>
                <VStack spacing={4}>
                    <FormControl isRequired>
                        <FormLabel>Title</FormLabel>
                        <Input
                            placeholder='Enter title'
                            value={title}
                            onChange={(e) => setTitle(e.target.value)}
                        />
                    </FormControl>
                    <FormControl isRequired>
                        <FormLabel>Maximum number of teams</FormLabel>
                        <Input
                            placeholder='Max teams'
                            value={maxTeams}
                            onChange={(e) => setMaxTeams(parseInt(e.target.value))}
                        />
                    </FormControl>
                    <FormControl isRequired>
                        <FormLabel>Maximum sum of prices</FormLabel>
                        <Input
                            placeholder='Max price'
                            value={maxPrice}
                            onChange={(e) => setMaxPrice(parseInt(e.target.value))}
                        />
                    </FormControl>
                    <FormControl isRequired>
                        <FormLabel>Deadline</FormLabel>
                        <Input
                            type='datetime-local'
                            value={deadline}
                            onChange={(e) => setDeadline(e.target.value)}
                        />
                    </FormControl>
                    <FormControl>
                        <FormLabel>Teams</FormLabel>
                        <Textarea
                            placeholder='Enter teams in the format "name price points", separated by new lines'
                            value={teamsStr}
                            onChange={(e) => setTeamsStr(e.target.value)}
                        />
                    </FormControl>
                    <Button type='submit' colorScheme='blue'>Submit</Button>
                </VStack>
            </form>
        </Box>
    </>
}
