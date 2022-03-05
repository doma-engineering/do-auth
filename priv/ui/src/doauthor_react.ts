import * as sodiumBootstrap from 'libsodium-wrappers';
import { require as r } from 'doauthor/src/doauthor';
import React from "react";

async function ensureDynLoaded(dynStatus: string, setDynStatus: React.Dispatch<React.SetStateAction<string>>) {
    if (!dynStatus) {
        await sodiumBootstrap.ready;
        const sodium = sodiumBootstrap;
        console.log(sodium.SODIUM_LIBRARY_VERSION_MAJOR, sodium.SODIUM_LIBRARY_VERSION_MINOR);
        const loadingStatus = await r();
        setDynStatus(loadingStatus);
    }
}

export default ensureDynLoaded;
