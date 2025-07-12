import React from "react";
import {
    Card,
    CardBody,
    Heading,
    Stat,
    StatLabel,
    StatNumber,
    StatHelpText,
    HStack,
    Badge,
    Text
} from '@chakra-ui/react';
import { TournamentMetrics as TournamentMetricsType } from "@/src/services/statsService";

type TournamentMetricsProps = {
    metrics: TournamentMetricsType;
}

export default function TournamentMetrics({ metrics }: TournamentMetricsProps) {
    const getAccuracyColor = (accuracy: number) => {
        if (accuracy >= 90) return 'green';
        if (accuracy >= 75) return 'blue';
        if (accuracy >= 60) return 'orange';
        return 'red';
    };

    const getBiasColor = (bias: number) => {
        const absBias = Math.abs(bias);
        if (absBias <= 2) return 'green';
        if (absBias <= 5) return 'yellow';
        return 'red';
    };

    const getBiasText = (bias: number) => {
        if (bias > 0) return 'Questions were easier than expected';
        return 'Questions were harder than expected';
    };

    return (
        <Card mb={6}>
            <CardBody>
                <Heading as="h3" size="md" mb={4}>
                    Tournament Metrics
                </Heading>
                
                <HStack spacing={8} align="start">
                    <Stat>
                        <StatLabel>Difficulty Bias</StatLabel>
                        <StatNumber>
                            <Badge colorScheme={getBiasColor(metrics.difficultyBias)} fontSize="lg" p={2}>
                                {metrics.difficultyBias > 0 ? '+' : ''}{metrics.difficultyBias}
                            </Badge>
                        </StatNumber>
                        <StatHelpText>
                            <Text fontSize="sm">{getBiasText(metrics.difficultyBias)}</Text>
                        </StatHelpText>
                    </Stat>

                    <Stat>
                        <StatLabel>Prediction Accuracy</StatLabel>
                        <StatNumber>
                            <Badge colorScheme={getAccuracyColor(metrics.accuracy)} fontSize="lg" p={2}>
                                {metrics.accuracy}%
                            </Badge>
                        </StatNumber>
                    </Stat>
                </HStack>
            </CardBody>
        </Card>
    );
}
