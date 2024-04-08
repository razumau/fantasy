import React from "react";
import {Box, Flex, Text, Link} from "@chakra-ui/react";
import {UserButton} from "@clerk/nextjs";

export default function TournamentLayout({children}: {
    children: React.ReactNode
}) {
    return (
        <Flex flexDirection="column" minH="100vh">
            <Flex justifyContent="flex-end" p={4}>
                <UserButton/>
            </Flex>
            <Box flex="1">
                {children}
            </Box>
            <Flex as="footer" width="full" align="center" justifyContent="center" p={4}>
                <Text fontSize='sm' mr={2}>Made by Jury Razumau.</Text>
                <Link fontSize='sm' href="https://www.buymeacoffee.com/yourusername" isExternal>
                    You can buy me a coffee.
                </Link>
            </Flex>
        </Flex>
    );
}
