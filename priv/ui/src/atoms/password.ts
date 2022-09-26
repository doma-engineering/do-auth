import { atom } from 'jotai';
import { Ureu } from '../doauth/base';
import {
    deriveSigningKeypair,
    mainKey,
    SigningKeypair,
} from '../doauth/crypto';
import { atomWithSessionStorage } from './helpsFunctions';

export const keyPairSessionStorage =
    atomWithSessionStorage<SigningKeypair<Ureu> | null>('doauth_keypair', null);

export const makeKeypairAndSaveToSessionStorage = atom(
    (get) => get(keyPairSessionStorage),
    async (
        get,
        set,
        { password, email }: { password: string; email?: string }
    ) => {
        const mainKeyValue = await mainKey(
            password,
            (typeof email === 'string' && {
                saltOverride: email.toLowerCase(),
            }) ||
                {}
        );
        const keyPair = await deriveSigningKeypair(mainKeyValue, 1);
        set(keyPairSessionStorage, keyPair);
    }
);
