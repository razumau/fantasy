'use client'

import React, { useState, FormEvent } from 'react';
import {Tournament} from "@/app/tournaments/[tournamentSlug]/types";
import { format, parseISO } from 'date-fns';
import {
    Box, 
    FormControl, 
    FormLabel, 
    Input, 
    Button, 
    VStack, 
    HStack,
    Heading, 
    Alert, 
    AlertIcon,
    Table,
    Thead,
    Tbody,
    Tr,
    Th,
    Td,
    TableContainer,
    NumberInput,
    NumberInputField,
    NumberInputStepper,
    NumberIncrementStepper,
    NumberDecrementStepper
} from '@chakra-ui/react';
import {updateTournamentWithTeams, fetchResults} from "@/app/actions";

type Team = {
    id: number;
    name: string;
    price: number;
    points: number;
    tournamentId: number;
}

type EditTournamentProps = {
    tournament: Omit<Tournament, 'isOpen'>;
    teams: Team[];
}

export default function EditTournament({ tournament, teams: initialTeams }: EditTournamentProps) {
    const [title, setTitle] = useState(tournament.title);
    const [deadline, setDeadline] = useState(format(tournament.deadline, "yyyy-MM-dd'T'HH:mm"));
    const [maxTeams, setMaxTeams] = useState(tournament.maxTeams);
    const [maxPrice, setMaxPrice] = useState(tournament.maxPrice);
    const [spreadsheetUrl, setSpreadsheetUrl] = useState(tournament.spreadsheetUrl || '');
    const [teamColumnName, setTeamColumnName] = useState(tournament.teamColumnName || '');
    const [resultColumnName, setResultColumnName] = useState(tournament.resultColumnName || '');
    const [teams, setTeams] = useState(initialTeams);
    const [isLoading, setIsLoading] = useState(false);
    const [message, setMessage] = useState('');

    const handleTeamChange = (teamId: number, field: 'name' | 'price' | 'points', value: string | number) => {
        setTeams(prevTeams => 
            prevTeams.map(team => 
                team.id === teamId 
                    ? { ...team, [field]: value }
                    : team
            )
        );
    };

    const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
        event.preventDefault();
        setIsLoading(true);
        setMessage('');
        
        try {
            const deadlineDate = parseISO(deadline);
            await updateTournamentWithTeams({
                id: tournament.id, 
                title, 
                deadline: deadlineDate, 
                maxTeams, 
                maxPrice,
                spreadsheetUrl: spreadsheetUrl || null,
                teamColumnName: teamColumnName || null,
                resultColumnName: resultColumnName || null
            }, teams);
            
            setMessage('Tournament updated successfully!');
        } catch (error) {
            setMessage('Error: ' + (error instanceof Error ? error.message : 'Unknown error'));
        } finally {
            setIsLoading(false);
        }
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
            // Refresh teams data after fetching results
            window.location.reload();
        } catch (error) {
            setMessage('Error: ' + (error instanceof Error ? error.message : 'Unknown error'));
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <Box maxW="1200px" mx="auto" p={5}>
            <Heading textAlign={'center'} mx={2} mb={6}>{tournament.title}</Heading>
            
            <Box p={5} shadow='md' borderWidth='1px' mb={6}>
                <Heading mb={6} size="md">Tournament Details</Heading>
                <form onSubmit={handleSubmit}>
                    <VStack spacing={4}>
                        <HStack spacing={4} width="100%">
                            <FormControl isRequired>
                                <FormLabel>Title</FormLabel>
                                <Input
                                    placeholder='Enter title'
                                    value={title}
                                    onChange={(e) => setTitle(e.target.value)}
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
                        </HStack>
                        
                        <HStack spacing={4} width="100%">
                            <FormControl isRequired>
                                <FormLabel>Maximum number of teams</FormLabel>
                                <NumberInput 
                                    value={maxTeams} 
                                    onChange={(_, value) => setMaxTeams(value)}
                                    min={1}
                                    max={20}
                                >
                                    <NumberInputField />
                                    <NumberInputStepper>
                                        <NumberIncrementStepper />
                                        <NumberDecrementStepper />
                                    </NumberInputStepper>
                                </NumberInput>
                            </FormControl>
                            <FormControl isRequired>
                                <FormLabel>Maximum sum of prices</FormLabel>
                                <NumberInput 
                                    value={maxPrice} 
                                    onChange={(_, value) => setMaxPrice(value)}
                                    min={1}
                                    max={1000}
                                >
                                    <NumberInputField />
                                    <NumberInputStepper>
                                        <NumberIncrementStepper />
                                        <NumberDecrementStepper />
                                    </NumberInputStepper>
                                </NumberInput>
                            </FormControl>
                        </HStack>

                        <HStack spacing={4} width="100%">
                            <FormControl>
                                <FormLabel>URL for results spreadsheet</FormLabel>
                                <Input
                                    placeholder='If this tournament uses a spreadsheet for results'
                                    value={spreadsheetUrl}
                                    onChange={(e) => setSpreadsheetUrl(e.target.value)}
                                />
                            </FormControl>
                        </HStack>
                        
                        <HStack spacing={4} width="100%">
                            <FormControl>
                                <FormLabel>Team column name</FormLabel>
                                <Input
                                    placeholder='Column name with teams'
                                    value={teamColumnName}
                                    onChange={(e) => setTeamColumnName(e.target.value)}
                                />
                            </FormControl>
                            <FormControl>
                                <FormLabel>Result column name</FormLabel>
                                <Input
                                    placeholder='Σ'
                                    value={resultColumnName}
                                    onChange={(e) => setResultColumnName(e.target.value)}
                                />
                            </FormControl>
                        </HStack>
                        
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
                            <Button 
                                type='submit' 
                                colorScheme='blue'
                                isLoading={isLoading}
                                loadingText="Saving..."
                            >
                                Save Changes
                            </Button>
                        </HStack>
                    </VStack>
                </form>
            </Box>

            <Box p={5} shadow='md' borderWidth='1px'>
                <Heading mb={4} size="md">Teams</Heading>
                <TableContainer>
                    <Table variant="simple" size="sm">
                        <Thead>
                            <Tr>
                                <Th>ID</Th>
                                <Th>Team Name</Th>
                                <Th isNumeric>Price</Th>
                                <Th isNumeric>Points</Th>
                            </Tr>
                        </Thead>
                        <Tbody>
                            {teams.map((team) => (
                                <Tr key={team.id}>
                                    <Td fontFamily="mono" fontSize="sm" color="gray.600">
                                        {team.id}
                                    </Td>
                                    <Td>
                                        <Input
                                            value={team.name}
                                            onChange={(e) => handleTeamChange(team.id, 'name', e.target.value)}
                                            size="sm"
                                            variant="flushed"
                                        />
                                    </Td>
                                    <Td>
                                        <NumberInput 
                                            value={team.price} 
                                            onChange={(_, value) => handleTeamChange(team.id, 'price', value)}
                                            min={0}
                                            max={200}
                                            size="sm"
                                        >
                                            <NumberInputField />
                                            <NumberInputStepper>
                                                <NumberIncrementStepper />
                                                <NumberDecrementStepper />
                                            </NumberInputStepper>
                                        </NumberInput>
                                    </Td>
                                    <Td>
                                        <NumberInput 
                                            value={team.points} 
                                            onChange={(_, value) => handleTeamChange(team.id, 'points', value)}
                                            min={0}
                                            max={1000}
                                            size="sm"
                                        >
                                            <NumberInputField />
                                            <NumberInputStepper>
                                                <NumberIncrementStepper />
                                                <NumberDecrementStepper />
                                            </NumberInputStepper>
                                        </NumberInput>
                                    </Td>
                                </Tr>
                            ))}
                        </Tbody>
                    </Table>
                </TableContainer>
            </Box>
        </Box>
    );
}
