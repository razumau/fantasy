import React from "react";
import {fetchAdminStatus} from "@/src/services/userService";
import CreateTournament from "@/app/tournaments/create/CreateTournament";

export default async function Page() {
    const isAdmin = await fetchAdminStatus();
    if (!isAdmin) {
        throw new Error('You are not allowed here');
    }

    return <CreateTournament />
}
