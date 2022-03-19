import { toT, Ureus } from './base';
import { isoUtcNow } from './util';

export type Proof<T> = {
    verificationMethod: string;
    signature: T;
    timestamp: string;
};

export async function fromSignature<T extends Ureus>(
    issuer: string,
    signature: Ureus,
    t?: T
): Promise<Proof<T>> {
    return {
        verificationMethod: issuer,
        signature: await toT(signature, t),
        timestamp: isoUtcNow(),
    };
}
