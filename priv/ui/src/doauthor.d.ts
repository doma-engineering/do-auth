import { server } from "typescript";

declare module 'doauthor/src/doauthor' {
    export type params = { ops: number, mem: number, saltSize: number };
    export type kp = { public: any, secret: any } // I don't remember how to say ByteArray in JS
    export async function require(): string;
    declare var sodium: any; // We need to type Sodium at some point, but now it doesn't matter much.
    declare var __doauthorHasLoaded__: boolean;
    declare var doauthor: {
        server: server,
        saltSize: number,
        hashSize: number,
        keySize: number,
        defaultParams: {
            opsLimit: number,
            memLimit: number
        },
        crypto: {
            show: (bs: any) => string, // Any here should be bytearray, whatever it is in JS
            read: (bs: string) => any, // Same here!
            slipConfig: () => params,
            mainKey: (pass: string) => any, // I don't remember the type for this. Another TODO
            mainKeyInit2: (pass: string, slipConfig: params) => [any, any], // Again, don't remember the type
            mainKeyReproduce2: (pass: string, slip: any) => any,
            deriveSigningKeypair: (mkey: any, n: number) => kp,
            sign: (msg: string, kp: kp) => { public: any, signature: any }, // Don't remember the type for signature, TODO
            verify: (msg: string, detached: { public: any, signature: any }) => boolean, // I guess... Verify should return a bool? lol
            bland_hash: (msg: string) => string,
            sign_map: (kp: kp, the_map: object, overrides: object) => object, // ... I mean...
            verify_map: (verifiable_map: object, overrides: object) => boolean,
            canonicalise: (x: any) => any[],
        },
        proof: {
            from_signature64: (issuer: any, sig64: string) => { verificationMethod: any, signature: string, timestamp: string },
            from_signature: (issuer: any, sig: any) => { verificationMethod: any, signature: string, timestamp: string },
        },
        credential: {
            from_claim: (kp: kp, claim: object, misc: object) => object,
            present_credential: (kp: kp, cred: object, misc: object) => object,
            proofless: (cred: object) => { '@context': string | string[], type: string | string[], issuer: any, issuanceDate: any, credentialSubject: any },
            prooflessJSON: (cred: object) => string,
            verify: (cred: object, pk: any) => boolean,
            verify64: (cred: object, pk: any) => boolean,
        },
        did: {
            from_pk: (pk: any) => string,
            from_pk64: (pk64: string) => string,
            recallPublicKey: (did_str: string) => string?,
            fetchPublicKey: (did_str: string) => Promise<string>,
            memorisePublicKey64: (pk64: string) => any, // What does localStorage.setItem return?
            memorisePublicKey: (pk: any) => any, // What does localStorage.setItem return?
        },
        util: {
            prettyPrint: (x: any) => string,
            isoUtcNowOld: () => string,
            isoUtcNow: () => string,
        }
    };
    export const observePeriodMsec: number;
    export async function observeMany(varsF: () => boolean[], timeLeft: number?);
}
