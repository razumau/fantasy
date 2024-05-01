import {Container, Box, Heading, Link, Text} from '@chakra-ui/react';
import NextLink from "next/link";
import React from "react";

export default function PrivacyPolicy() {
    return (
        <Container maxW='4xl' centerContent>
            <Box maxW='2xl'>
                <Heading pb='2' as='h2' size='lg'>These tournaments are active:</Heading>
                <Text pt='2'><Link as={NextLink} href={`/tournaments/schr-2024`}>СЧР 2024</Link></Text>
                <Heading pt='4' pb='2' as='h2' size='lg'>See results for completed tournaments:</Heading>
                <Text pt='2'><Link as={NextLink} href={`/tournaments/pl-2024/results`}>Чемпионат Польши 2024</Link></Text>
                <Text pt='2'><Link as={NextLink} href={`/tournaments/shchr-2024/results`}>ШЧР 2024</Link></Text>
            </Box>
        </Container>
    );
}
