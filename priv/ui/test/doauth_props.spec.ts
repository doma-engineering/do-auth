import sodium0 from 'libsodium-wrappers';
import { testProp, fc } from 'jest-fast-check';
import { test, expect } from '@jest/globals';
import { toUrl } from '../src/doauth/base';
import {
    blandHash,
    Cannable,
    deriveSigningKeypair,
    mainKey,
    sign,
    signMap,
    verify,
    verifyMap,
} from '../src/doauth/crypto';
import { performance } from 'perf_hooks';

// This should actually be checked in browser but ok
test('libsodium loads fast', async () => {
    const t000 = performance.now();
    await sodium0.ready;
    const t290 = performance.now();
    await sodium0.ready;
    const t300 = performance.now();
    expect(t300 - t000).toBeLessThan(300);
    expect(t300 - t290).toBeLessThan(10);
    const sodium = sodium0;
    expect(sodium.SODIUM_VERSION_STRING).toBeTruthy;
    expect(
        (await toUrl(sodium.crypto_generichash(32, 'Glory to Ukraine'))).encoded
    ).toBe('UjuhVEXQembMCmLfemONVeBKhDCEeXbTtgiht472zGA=');
});

testProp('bland hash works on arbitrary data', [fc.string()], async (x) => {
    const x1 = x + '1';
    const hx = await blandHash(x);
    const h1x = await blandHash(x);
    const hx1 = await blandHash(x1);
    const h1x1 = await blandHash(x1);
    expect(hx.encoded == h1x.encoded).toBe(true);
    expect(hx1.encoded == h1x1.encoded).toBe(true);
    expect(hx.encoded != hx1.encoded).toBe(true);
});

testProp('toUrl is tripping', [fc.string(), fc.uint8Array()], async (x, y) => {
    const x8: Uint8Array = new TextEncoder().encode(x);
    const xe = await toUrl(x8);
    expect(new TextDecoder().decode(xe.raw)).toBe(x);
    expect(await toUrl(xe.raw)).toStrictEqual(xe);

    const ye = await toUrl(y);
    expect(ye.raw).toBe(y);
    expect(await toUrl(ye.raw)).toStrictEqual(ye);
});

testProp(
    'main key is derivable',
    [fc.string(), fc.string()],
    async (password, msg) => {
        const mkey = await mainKey(password);
        const skp = await deriveSigningKeypair(mkey, 4);
        const detachedSig = await sign(msg, skp);
        expect(await verify(msg, detachedSig)).toBe(true);
    }
);

testProp(
    'maps are verifiable',
    [fc.string(), fc.object()],
    async (password, xkv) => {
        const noVoid = (xkv: object): boolean => {
            if (xkv === null) {
                return false;
            }
            return Object.entries(xkv).reduce<boolean>((acc, [, v]) => {
                if (!acc) {
                    return false;
                }
                if (typeof v === 'object') {
                    return noVoid(v);
                }
                return acc && v !== null && typeof v !== 'undefined';
            }, true);
        };
        fc.pre(noVoid(xkv));
        const skp = await deriveSigningKeypair(await mainKey(password), 4);
        const vxkv = await signMap(skp, xkv as Record<string, Cannable>);
        expect(await verifyMap(vxkv)).toBe(true);
    }
);
