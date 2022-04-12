import sodium0 from 'libsodium-wrappers';

export interface Raw {
    raw: Uint8Array;
}

export interface Encoded {
    encoded: string;
}

export interface Url extends Raw, Encoded {}

export type Ureu = Uint8Array | Raw | Encoded | Url;

export async function toUrl(x: Ureu): Promise<Url> {
    if (isUrl(x)) {
        return x;
    }
    await sodium0.ready;
    const sodium = sodium0;
    // U
    if (x instanceof Uint8Array) {
        return {
            raw: x,
            encoded: sodium.to_base64(x, sodium.base64_variants['URLSAFE']),
        };
    }
    // RU
    if (isRaw(x)) {
        return toUrl(x.raw);
    }
    // E
    return {
        raw: sodium.from_base64(x.encoded, sodium.base64_variants['URLSAFE']),
        encoded: x.encoded,
    };
}

export function isUrl(x: unknown): x is Raw & Encoded {
    return isRaw(x) && isEncoded(x);
}

export function isRaw(x: unknown): x is Raw {
    return typeof x === 'object' && x !== null && x.hasOwnProperty('raw');
}

export function isEncoded(x: unknown): x is Encoded {
    return typeof x === 'object' && x !== null && x.hasOwnProperty('encoded');
}

export const raw0: Raw = { raw: new Uint8Array() };
export const encoded0: Encoded = { encoded: '' };
export const url0: Url = { raw: raw0.raw, encoded: encoded0.encoded };

export async function toRaw(x: Ureu): Promise<Raw> {
    return { raw: (await toUrl(x)).raw };
}

export async function toEncoded(x: Ureu): Promise<Encoded> {
    return { encoded: (await toUrl(x)).encoded };
}

export async function toUnit8Array(x: Ureu): Promise<Uint8Array> {
    return (await toUrl(x)).raw;
}

export async function extractEncoded(x: Ureu): Promise<string> {
    return (await toUrl(x)).encoded;
}

export async function toT<T extends Ureu | string>(
    x: Ureu,
    t: undefined | T | string
): Promise<T | string> {
    // U
    if (typeof t === 'undefined' || isUrl(t)) {
        return (await toUrl(x)) as T;
    }
    // E
    if (isEncoded(t)) {
        return (await toEncoded(x)) as T;
    }
    // R
    if (isRaw(t)) {
        return (await toRaw(x)) as T;
    }
    if (typeof t === 'string') {
        return await extractEncoded(x);
    }
    // U
    return (await toUnit8Array(x)) as T;
}
