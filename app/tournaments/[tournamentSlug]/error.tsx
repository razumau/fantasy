'use client'

import { Center, Text, Box } from '@chakra-ui/react';
import { Link } from '@chakra-ui/next-js'

export default function Error({error}: { error: Error }) {
    return (
        <Center height="100vh">
            <Box textAlign="center">
                <Text fontSize="4xl" fontWeight="bold">
                    {error.message}
                </Text>
                <Link href='/'>Go to main page</Link>
            </Box>
        </Center>
    );
}