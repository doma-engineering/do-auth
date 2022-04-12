import { extractEncoded, Ureu } from './base';
import { Cannable, SigningKeypair, signMap } from './crypto';
import { isoUtcNow } from './util';

export async function mkCredential(
    kp: SigningKeypair<Ureu>,
    payloadMap: Record<string, Cannable>,
    meta?: Record<string, unknown>
): Promise<Record<string, Cannable>> {
    // We use datetime strings, but probably, moving forward, we need to accept
    // JS Date objects like Elixir implementation does.
    const tau0 = isoUtcNow();
    const issuer = await extractEncoded(kp.public);
    var credSoFar: Record<string, Cannable> = {
        '@context': [],
        type: [],
        issuer: issuer,
        issuanceDate: tau0,
        credentialSubject: payloadMap,
    };
    if (typeof meta !== 'undefined') {
        ['effectiveDate', 'validFrom', 'validUntil'].forEach((x) => {
            if (!(x in credSoFar) && x in meta && typeof meta[x] === 'string') {
                credSoFar[x] = meta[x] as string;
            }
        });
        ['issuanceDate'].forEach((x) => {
            if (x in meta && typeof meta[x] == 'string') {
                credSoFar[x] = meta[x] as string;
            }
        });
    }
    return signMap(kp, credSoFar);
}

export async function presentCredential(
    kp: SigningKeypair<Ureu>,
    cred: Record<string, Cannable>,
    meta?: Record<string, unknown>
): Promise<Record<string, Cannable>> {
    var presentationClaimSoFar: Record<string, Cannable> = {
        verifiableCredential: cred,
        issuer: await extractEncoded(kp.public),
    };
    if (typeof meta !== 'undefined') {
        ['id', 'holder', 'credentialSubject'].forEach((x) => {
            if (!(x in presentationClaimSoFar) && typeof meta[x] === 'string') {
                presentationClaimSoFar[x] = meta[x] as string;
            }
        });
        ['issuanceDate'].forEach((x) => {
            if (x in meta) {
                presentationClaimSoFar[x] = meta[x] as string;
            }
        });
    }
    return await signMap(kp, presentationClaimSoFar);
}
