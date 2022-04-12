import { toT, Ureu } from './base';
import { isoUtcNow } from './util';

export type Proof<T> = {
    verificationMethod: string;
    signature: T;
    timestamp: string;
};

export async function fromSignature<T extends Ureu | string>(
    issuer: string,
    signature: Ureu,
    t?: T | string
): Promise<Proof<T | string>> {
    return {
        verificationMethod: issuer,
        signature: await toT(signature, t),
        timestamp: isoUtcNow(),
    };
}

// This actuially doesn't check T
export function isProof<T>(xkv: unknown): xkv is Proof<T> {
    if (typeof xkv === 'object' && xkv !== null) {
        const x = xkv as Object;
        return (
            x.hasOwnProperty('verificationMethod') &&
            typeof (x as any)['verificationMethod'] === 'string' &&
            x.hasOwnProperty('signature') &&
            x.hasOwnProperty('timestamp') &&
            typeof (x as any)['timestamp'] === 'string'
        );
    }
    return false;
}
