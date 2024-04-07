import {Text} from '@chakra-ui/react'
import { formatDistance, format } from 'date-fns';

type TournamentInfoProps = {
    deadline: Date;
    maxTeams: number;
    isOpen: boolean;
}

export default function TournamentInfo({ maxTeams, deadline, isOpen }: TournamentInfoProps) {
    const formattedDate = format(deadline, "H:mm 'on' dd.MM.yyyy");
    const timeRemaining = formatDistance(new Date(), deadline, { includeSeconds: true });

    if (isOpen) {
        return (
            <>
                <Text pt={2}>Select up to {maxTeams} teams. Your result is the sum of their points.</Text>
                <Text pt={2}>You can change your picks until {formattedDate} (you have {timeRemaining} left).</Text>
            </>
        )
    } else {
        return (
            <>
                <Text>This tournament is closed since {formattedDate}, you can’t change your picks anymore.</Text>
            </>
        )
    }


}
