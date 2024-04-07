import React from "react";
import {Box, Flex, Text, Link, Divider} from "@chakra-ui/react";
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
            <Divider></Divider>
            <Flex as="footer" width="full" align="center" justifyContent="center" p={4}>
                <Text mr={2}>Made by Jury Razumau.</Text>
                <Link href="https://www.buymeacoffee.com/juryrazumau" isExternal>
                    You can buy me a coffee.
                </Link>
            </Flex>
        </Box>
    )
}
