import { Ureu } from '../doauth/base';
import { SigningKeypair } from '../doauth/crypto';
import { atomWithSessionStorage } from './helpsFunctions';

export const keyPairSessionStorage =
    atomWithSessionStorage<SigningKeypair<Ureu> | null>('doauth_keypair', null);
