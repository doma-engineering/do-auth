import * as sodium0 from 'libsodium-wrappers';

export interface Raw {
    raw: Uint8Array;
}

export interface Encoded {
    encoded: string;
}

export interface Url extends Raw, Encoded {}

export type Ureus = Uint8Array | Raw | Encoded | Url | string;

export async function toUrl(x: Ureus): Promise<Url> {
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
    // S
    if (typeof x === 'string') {
        return {
            raw: sodium.from_base64(x, sodium.base64_variants['URLSAFE']),
            encoded: x,
        };
    }
    // RU
    if (isRaw(x)) {
        return toUrl(x.raw);
    }
    // E
    return toUrl(x.encoded);
}

export async function fromString(x: string): Promise<Url> {
    await sodium0.ready;
    const sodium = sodium0;
    return {
        raw: sodium.from_base64(x, sodium.base64_variants['URLSAFE']),
        encoded: x,
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

export async function toRaw(x: Ureus): Promise<Raw> {
    return { raw: (await toUrl(x)).raw };
}

export async function toEncoded(x: Ureus): Promise<Encoded> {
    return { encoded: (await toUrl(x)).encoded };
}

export async function toString1(x: Ureus): Promise<string> {
    return (await toUrl(x)).encoded;
}

export async function toUnit8Array(x: Ureus): Promise<Uint8Array> {
    return (await toUrl(x)).raw;
}

export async function toT<T extends Ureus>(
    x: Ureus,
    t: undefined | T
): Promise<T> {
    // U
    if (typeof t === 'undefined' || isUrl(t)) {
        return (await toUrl(x)) as T;
    }
    // S
    if (typeof t === 'string') {
        return (await toString1(x)) as T;
    }
    // E
    if (isEncoded(t)) {
        return (await toEncoded(x)) as T;
    }
    // R
    if (isRaw(t)) {
        return (await toRaw(x)) as T;
    }
    // U
    return (await toUnit8Array(x)) as T;
}
