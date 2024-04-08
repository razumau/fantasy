import {Text, Container, Box, Heading} from '@chakra-ui/react';

export default function PrivacyPolicy() {
    return (
        <Container maxW='4xl' centerContent>
        <Box maxW='2xl'>
            <Heading as='h1' size='xl'>Privacy Policy for fantasy.razumau.net</Heading>
            <Heading pt='4' as='h2' size='lg'>What we collect and why</Heading>
            <Text pt='2'>To identify players, we collect emails and usernames.</Text>
            <Text pt='2'>To log in players, we use Clerk.com. See their privacy policy here: https://clerk.com/legal/privacy.</Text>
            <Text pt='2'>In our database, we store a clerkId provided by Clerk.com and a username (which might be built from user’s first name and last name).</Text>
            <Text pt='2'>These usernames will be publicly shown in tables of results for each tournament you take part in.</Text>
            <Heading pt='4' as='h2' size='lg'>Right to Erasure</Heading>
            <Text pt='2'>To request deletion of all data related to your account, contact me at fantasy@razumau.net</Text>
        </Box>
        </Container>
    );
}
