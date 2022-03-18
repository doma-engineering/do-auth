import { Url } from './base';
import { isoUtcNow } from './util';

export type Proof<T> = {
    verificationMethod: string;
    signature: T;
    timestamp: string;
};

export function fromSignature(issuer: string, signature: Url): Proof<Url> {
    return {
        verificationMethod: issuer,
        signature: signature,
        timestamp: isoUtcNow(),
    };
}

//export function fromSignature64(issuer: string, signature: string);
