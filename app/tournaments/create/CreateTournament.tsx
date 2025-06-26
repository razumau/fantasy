'use client'

import React, { useState, FormEvent } from 'react';
import { format, addDays } from 'date-fns';
import {Box, FormControl, FormLabel, Input, Textarea, Button, VStack, Heading, Alert, AlertIcon} from '@chakra-ui/react';
import {createTournament} from "@/app/actions";
import { useRouter } from 'next/navigation';

export default function CreateTournament() {
    const router = useRouter();
    const [title, setTitle] = useState('');
    const [slug, setSlug] = useState('');
    const [deadline, setDeadline] = useState(format(addDays(new Date(), 7), "yyyy-MM-dd'T'HH:mm"));
    const [maxTeams, setMaxTeams] = useState(5);
    const [maxPrice, setMaxPrice] = useState(100);
    const [spreadsheetUrl, setSpreadsheetUrl] = useState('');
    const [teamColumnName, setTeamColumnName] = useState('');
    const [resultColumnName, setResultColumnName] = useState('');
    const [teamsStr, setTeamsStr] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const [message, setMessage] = useState('');

    const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
        event.preventDefault();
        
        if (!title.trim() || !slug.trim() || !teamsStr.trim()) {
            setMessage('Error: Title, slug, and teams are required');
            return;
        }

        setIsLoading(true);
        setMessage('');
        
        try {
            const deadlineDate = new Date(deadline);
            await createTournament({
                title,
                slug,
                deadline: deadlineDate,
                maxTeams,
                maxPrice,
                spreadsheetUrl: spreadsheetUrl || null,
                teamColumnName: teamColumnName || null,
                resultColumnName: resultColumnName || null
            }, teamsStr);
            
            setMessage('Tournament created successfully!');
            setTimeout(() => {
                router.push(`/tournaments/${slug}`);
            }, 1500);
        } catch (error) {
            setMessage('Error: ' + (error instanceof Error ? error.message : 'Unknown error'));
        } finally {
            setIsLoading(false);
        }
    };

    const handleTitleChange = (value: string) => {
        setTitle(value);
    };

    return (
        <Box p={5} shadow='md' borderWidth='1px' maxW="800px" mx="auto">
            <Heading mb={6} textAlign="center">Create tournament</Heading>
            <form onSubmit={handleSubmit}>
                <VStack spacing={4}>
                    <FormControl isRequired>
                        <FormLabel>Title</FormLabel>
                        <Input
                            value={title}
                            onChange={(e) => handleTitleChange(e.target.value)}
                        />
                    </FormControl>
                    
                    <FormControl isRequired>
                        <FormLabel>Slug</FormLabel>
                        <Input
                            placeholder='krakow-2025'
                            value={slug}
                            onChange={(e) => setSlug(e.target.value)}
                        />
                    </FormControl>
                    
                    <FormControl isRequired>
                        <FormLabel>Maximum number of teams</FormLabel>
                        <Input
                            type="number"
                            placeholder='Max teams'
                            value={maxTeams}
                            onChange={(e) => setMaxTeams(parseInt(e.target.value))}
                        />
                    </FormControl>
                    
                    <FormControl isRequired>
                        <FormLabel>Maximum sum of prices</FormLabel>
                        <Input
                            type="number"
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
                    
                    <FormControl isRequired>
                        <FormLabel>Teams</FormLabel>
                        <Textarea
                            placeholder='Enter teams in the format "name price", separated by new lines (e.g., "Team A 45")'
                            value={teamsStr}
                            onChange={(e) => setTeamsStr(e.target.value)}
                            rows={8}
                        />
                    </FormControl>
                    
                    {message && (
                        <Alert status={message.startsWith('Error') ? 'error' : 'success'}>
                            <AlertIcon />
                            {message}
                        </Alert>
                    )}
                    
                    <Button 
                        type='submit' 
                        colorScheme='blue' 
                        width="100%"
                        isLoading={isLoading}
                        loadingText="Creating..."
                    >
                        Create Tournament
                    </Button>
                </VStack>
            </form>
        </Box>
    );
}
