import React from "react";
import {Box, Flex} from "@chakra-ui/react";
import {UserButton} from "@clerk/nextjs";

export default function TournamentLayout({children}: {
    children: React.ReactNode
}) {
    return (
        <Box minH="100vh">
            <Flex justifyContent="flex-end" p={4}>
                <UserButton/>
            </Flex>
            {children}
        </Box>
    )
}
