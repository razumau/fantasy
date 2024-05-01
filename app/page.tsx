import {Container, Box, Heading, Link} from '@chakra-ui/react';
import NextLink from "next/link";
import React from "react";

export default function PrivacyPolicy() {
    return (
        <Container maxW='4xl' centerContent>
            <Box maxW='2xl'>
                <Heading py='12' as='h2' size='lg'>These tournaments are active:</Heading>
                <Link pt='8' as={NextLink} href={`/tournaments/schr-2024`}>СЧР 2024</Link>
                <Heading py='12' as='h2' size='lg'>See results for completed tournaments:</Heading>
                <Link pt='8' as={NextLink} href={`/tournaments/pl-2024/results`}>Чемпионат Польши 2024</Link>
                <Link pt='8' as={NextLink} href={`/tournaments/shchr-2024/results`}>ШЧР 2024</Link>
            </Box>
        </Container>
    );
}
