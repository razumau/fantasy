import React, { useState } from 'react';
import TeamsTable from "./TeamsTable";
import SelectedTeams from "./SelectedTeams";
import {savePicks} from "@/app/actions";
import {Tournament, Team, Picks} from "./types";
import {Box, Card, CardBody, Divider, Grid, Link, useToast} from '@chakra-ui/react';
import TournamentInfo from "@/app/tournaments/[tournamentSlug]/TournamentInfo";

interface SelectionState {
    selectedTeams: Team[];
    totalSelectedPrice: number;
    version: number;
}

interface TeamsSelectorProps {
    teams: Team[];
    tournament: Tournament;
    picks: Picks;
}

export default function TeamsSelector({ teams, tournament, picks }: TeamsSelectorProps) {
    const [selection, setSelection] = useState<SelectionState>(
        { selectedTeams: picks.teams, totalSelectedPrice: picks.totalSelectedPrice, version: picks.version });
    const toast = useToast();

    const showError = (message: string) => {
        toast({
            title: message,
            isClosable: true,
            status: 'error',
            duration: 5000,
            position: 'top'
        })
    }

    const handleCheckboxChange = async (selectedTeam: Team) => {
        toast.closeAll();
        const removingTeam = selection.selectedTeams.find(team => team.id === selectedTeam.id);
        let newState: SelectionState;

        if (removingTeam) {
            newState = {
                selectedTeams: selection.selectedTeams.filter(team => team.id !== selectedTeam.id),
                totalSelectedPrice: selection.totalSelectedPrice - selectedTeam.price,
                version: selection.version + 1,
            }
        } else {
            if (selection.selectedTeams.length < tournament.maxTeams
                    && (selection.totalSelectedPrice + selectedTeam.price) <= tournament.maxPrice) {
                newState = {
                    selectedTeams: [...selection.selectedTeams, selectedTeam],
                    totalSelectedPrice: selection.totalSelectedPrice + selectedTeam.price,
                    version: selection.version + 1,
                }
            } else {
                newState = selection;
                if (selection.selectedTeams.length >= tournament.maxTeams) {
                    showError("Too many teams");
                }
                if ((selection.totalSelectedPrice + selectedTeam.price) > tournament.maxPrice) {
                    showError("You don’t have enough points")
                }
            }
        }
        if (selection.version == newState.version) {
            return;
        }

        setSelection(newState);

        try {
            await savePicks({
                teamIds: newState.selectedTeams.map(team => team.id),
                tournamentId: tournament.id,
                version: newState.version
            });
        } catch {
            setSelection(selection);
        }
    };

    const selectedTeamIds = selection.selectedTeams.map(team => team.id);

    return (
        <Box px={4} py={8}>
            <Grid
                templateColumns={{ base: "repeat(1, 1fr)", md: "repeat(3, 1fr)" }}
                gap={4}
            >
                <Box display={{ base: "block", md: "block" }} order={{ base: 1, md: 3 }}>

                    <Card>
                        <CardBody>
                            <TournamentInfo
                                maxTeams={tournament.maxTeams}
                                deadline={tournament.deadline}
                                isOpen={tournament.isOpen}
                            />
                        </CardBody>
                        <Box position='relative' px='5'>
                            <Divider colorScheme={'blue'}></Divider>
                        </Box>
                        <CardBody>
                            <SelectedTeams
                                teams={selection.selectedTeams}
                                maxPrice={tournament.maxPrice}
                                isOpen={tournament.isOpen}
                            />
                        </CardBody>
                        <Box position='relative' px='5'>
                            <Divider colorScheme={'blue'}></Divider>
                        </Box>
                        <Link pl='5' pt='3' href={`/tournaments/${tournament.slug}/results`}>See picks by other players.</Link>
                        <Link pl='5' py='3' href={`/tournaments/${tournament.slug}/popular`}>What are the most popular teams?</Link>
                    </Card>
                </Box>

                <Box order={{ base: 2, md: 2 }}>
                    <TeamsTable teams={teams}
                                selectedTeamIds={selectedTeamIds}
                                handleCheckboxChange={handleCheckboxChange}
                                isOpen={tournament.isOpen}
                    />
                </Box>

                <Box display={{ base: "none", md: "block" }} order={{ md: 1 }}></Box>
            </Grid>
        </Box>
    )
}
