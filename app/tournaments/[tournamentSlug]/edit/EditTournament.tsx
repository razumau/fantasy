'use client'

import React, { useState, FormEvent } from 'react';
import {Tournament} from "@/app/tournaments/[tournamentSlug]/types";
import { format, parseISO } from 'date-fns';
import {Box, FormControl, FormLabel, Input, Textarea, Button, VStack, Heading, Alert, AlertIcon, HStack} from '@chakra-ui/react';
import {updateTournament, fetchResults} from "@/app/actions";

type EditTournamentProps = {
    tournament: Omit<Tournament, 'isOpen'>;
    teams: string;
}

export default function EditTournament({ tournament, teams }: EditTournamentProps) {
    const [title, setTitle] = useState(tournament.title);
    const [deadline, setDeadline] = useState(format(tournament.deadline, "yyyy-MM-dd'T'HH:mm"));
    const [maxTeams, setMaxTeams] = useState(tournament.maxTeams);
    const [maxPrice, setMaxPrice] = useState(tournament.maxPrice);
    const [spreadsheetUrl, setSpreadsheetUrl] = useState(tournament.spreadsheetUrl || '');
    const [teamColumnName, setTeamColumnName] = useState(tournament.teamColumnName || '');
    const [resultColumnName, setResultColumnName] = useState(tournament.resultColumnName || '');
    const [teamsStr, setTeamsStr] = useState(teams);
    const [isLoading, setIsLoading] = useState(false);
    const [message, setMessage] = useState('');

    const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
        event.preventDefault();
        const deadlineDate = parseISO(deadline);
        await updateTournament({
            id: tournament.id, 
            title, 
            deadline: deadlineDate, 
            maxTeams, 
            maxPrice,
            spreadsheetUrl: spreadsheetUrl || null,
            teamColumnName: teamColumnName || null,
            resultColumnName: resultColumnName || null
        }, teamsStr);
    };

    const handleFetchResults = async () => {
        if (!spreadsheetUrl || !teamColumnName || !resultColumnName) {
            setMessage('Configure spreadsheet URL, team column name, and result column name first');
            return;
        }

        setIsLoading(true);
        setMessage('');
        
        try {
            const result = await fetchResults(tournament.id);
            setMessage(result.message);
        } catch (error) {
            setMessage('Error: ' + (error instanceof Error ? error.message : 'Unknown error'));
        } finally {
            setIsLoading(false);
        }
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
                        <FormLabel>URL for results spreadsheet</FormLabel>
                        <Input
                            placeholder='If this tournament uses a spreadsheet for results'
                            value={spreadsheetUrl}
                            onChange={(e) => setSpreadsheetUrl(e.target.value)}
                        />
                    </FormControl>
                    <FormControl>
                        <FormLabel>Name of a column with teams</FormLabel>
                        <Input
                            placeholder=''
                            value={teamColumnName}
                            onChange={(e) => setTeamColumnName(e.target.value)}
                        />
                    </FormControl>
                    <FormControl>
                        <FormLabel>Name of a column with overall results</FormLabel>
                        <Input
                            placeholder='Σ'
                            value={resultColumnName}
                            onChange={(e) => setResultColumnName(e.target.value)}
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
                    
                    {message && (
                        <Alert status={message.startsWith('Error') ? 'error' : 'success'}>
                            <AlertIcon />
                            {message}
                        </Alert>
                    )}
                    
                    <HStack spacing={4} width="100%">
                        <Button 
                            onClick={handleFetchResults}
                            colorScheme='green'
                            isLoading={isLoading}
                            loadingText="Fetching..."
                            isDisabled={!spreadsheetUrl || !teamColumnName || !resultColumnName}
                        >
                            Fetch results
                        </Button>
                        <Button type='submit' colorScheme='blue'>Submit</Button>
                    </HStack>
                </VStack>
            </form>
        </Box>
    </>
}
