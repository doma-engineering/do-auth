import * as sodium0 from 'libsodium-wrappers';
import {
    toUrl,
    Encoded,
    Url,
    Raw,
    isUrl,
    isEncoded,
    Ureus,
    toRaw,
    toUnit8Array,
    toT,
} from './base';

export type Canned = number | bigint | string | Canned[][] | Canned[];
export type Canonicalised = Canned;

export type Cannable = string | number | bigint | CannableRec | Cannable[];
export type Canonicalisable = Cannable;

interface CannableRec extends Record<string, Cannable> {}

export type SigningKeypair<T> = { public: T; secret: T };
export type DetachedSignature<T> = { public: T; signature: T };

export function canonicalise(x: Cannable): Canned {
    const traceRet = <T>(x: T, pre?: string, post?: string): T => {
        // Silence warnings with noops
        ((x) => x)([pre, post]);
        //// Uncomment this to do some manual testing
        //console.debug(pre || "", JSON.stringify(x, null, 2), post || "");
        return x;
    };
    traceRet(x, 'Canonicalising ');
    if (
        typeof x === 'string' ||
        typeof x === 'number' ||
        typeof x === 'bigint'
    ) {
        return traceRet(x);
    } else if (Array.isArray(x)) {
        return x.map(canonicalise);
    } else {
        traceRet('Got an object that extends Record<string, Cannable>');
        return Object.entries(x)
            .sort()
            .map(([k, v]) => [traceRet(k, 'Processing key '), canonicalise(v)]);
    }
}

export interface Config {
    saltSize: number;
    hashSize: number;
    keySize: number;
    defaultParams: {
        opsLimit: number;
        memLimit: number;
    };
}

export interface SlipConfig {
    ops: number;
    mem: number;
    saltSize: number;
}
export interface Slip extends SlipConfig {
    salt: Encoded;
}

export async function getSodium(
    sodiumMaybe: typeof sodium0
): Promise<typeof sodium0> {
    await sodiumMaybe.ready;
    return sodiumMaybe;
}

export async function getSodiumAndCfg(
    sodiumMaybe: typeof sodium0
): Promise<{ sodium: typeof sodium0; cfg: Config }> {
    await sodiumMaybe.ready;
    return { sodium: sodiumMaybe, cfg: config(sodiumMaybe) };
}

export function config(sodium: typeof sodium0): Config {
    return {
        saltSize: 16,
        hashSize: 32,
        keySize: 32,
        defaultParams: {
            opsLimit: sodium.crypto_pwhash_OPSLIMIT_SENSITIVE,
            memLimit: 5 * sodium.crypto_pwhash_MEMLIMIT_MIN,
        },
    };
}

export function slipConfig(config: Config): SlipConfig {
    return {
        ops: config.defaultParams.opsLimit,
        mem: config.defaultParams.memLimit,
        saltSize: config.saltSize,
    };
}

export async function mainKeyFromLocalStorageSlip(pass: string) {
    const slipMaybe = localStorage.getItem('doauth_slip');
    if (slipMaybe) {
        return mainKeyReproduce(pass, JSON.parse(slipMaybe));
    } else {
        const { cfg } = await getSodiumAndCfg(sodium0);
        const [mkey, slip] = await mainKeyInit(pass, slipConfig(cfg));
        localStorage.setItem('doauth_slip', JSON.stringify(slip));
        return mkey;
    }
}
export const mainKey = mainKeyFromLocalStorageSlip;

export async function mainKeyReproduce(
    pass: string,
    slip: Slip
): Promise<Uint8Array> {
    const { sodium, cfg } = await getSodiumAndCfg(sodium0);
    const { ops, mem, salt } = slip;
    return sodium.crypto_pwhash(
        cfg.hashSize,
        pass,
        (await toRaw(salt)).raw,
        ops,
        mem,
        sodium.crypto_pwhash_ALG_DEFAULT
    );
}

export async function mainKeyInit(pass: string, scfg: SlipConfig) {
    const sodium = await getSodium(sodium0);
    const { encoded } = await toUrl(sodium.randombytes_buf(scfg.saltSize));
    const slip = {
        ...scfg,
        salt: { encoded },
    };
    const mkey = mainKeyReproduce(pass, slip);
    return [mkey, slip];
}

// With "Ureus" we're trying something new, which is basically duck-typing.
// I'm not too happy about accepting unwrapped, unvalidated strings / unit8arrays here, so perhaps the approach we take in Elixir is better.
// This approach guarantees no mess though and prevents from making a function per data acceptable underlying data type.
export async function deriveSigningKeypair<T extends Ureus>(
    mkey: Ureus,
    n: number,
    t: undefined | T
): Promise<SigningKeypair<T>> {
    const { sodium, cfg } = await getSodiumAndCfg(sodium0);
    const mkd = sodium.crypto_kdf_derive_from_key(
        cfg.keySize,
        n,
        'signsign',
        await toUnit8Array(mkey)
    );
    const { publicKey, privateKey } = sodium.crypto_sign_seed_keypair(mkd);
    return {
        public: (await toT(publicKey, t)) as T,
        secret: (await toT(privateKey, t)) as T,
    };
}

/*
export async function sign(msg: string, kp: SigningKeypairRaw): Promise<DetachedSignatureRaw> {
  const sodium = await getSodium(sodium0);
  return { public: kp.public, signature: sodium.crypto_sign_detached(msg, kp.secret) };
}

export async function verify(msg: string, detached: DetachedSignatureRaw): Promise<boolean> {
  const sodium = await getSodium(sodium0);
  return sodium.crypto_sign_verify_detached(detached.signature, msg, detached.public);
}

export async function blandHash(msg: string): Promise<Url> {
  const { sodium, cfg } = await getSodiumAndCfg(sodium0);
  return toUrl(sodium.crypto_generichash(cfg.hashSize, msg));
}

export async function signMap(kp: SigningKeypairRaw, theMap: Record<string, Cannable>, overrides: undefined | Record<string, any>): Record<string, Canned> {
  if (typeof overrides === 'undefined') {
    overrides = {};
  }
  const opts0 = {
    'proofField': 'proof',
    'signatureField': 'signature',
    'keyField': 'verificationMethod',
    'keyFieldConstructor': async (pk: Uint8Array) => (await toUrl(pk)).encoded,
    'ignore': ['id']
  };
  // Why Object.assign instead of spread here?
  const opts = Object.assign({}, opts0, overrides);
  var mut_theMap = { ...theMap };
  opts['ignore'].reduce(
    (acc, x) => delete (mut_theMap[x]), false
  );
  const toProve = { ...mut_theMap };
  const canonicalClaim = canonicalise(toProve);
  const detachedSignature = sign(JSON.stringify(canonicalClaim), kp);
  const did = opts["keyFieldConstructor"](kp.public);
  const issuer = did;
  const proofMap =
}
*/
