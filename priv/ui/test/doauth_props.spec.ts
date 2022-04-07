import * as sodium0 from 'libsodium-wrappers';
import { testProp, fc } from 'jest-fast-check';
import { test, expect } from '@jest/globals';
import { toUrl } from '../src/doauth/base';
import { blandHash } from '../src/doauth/crypto';

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
    expect(await toUrl(sodium.crypto_generichash(32, 'Glory to Ukraine'))).toBe(
        'UjuhVEXQembMCmLfemONVeBKhDCEeXbTtgiht472zGA='
    );
});

// testProp('bland hash works on arbitrary data', [fc.string()], async (x) => {
//     const x1 = x + '1';
//     const hx = await blandHash(x);
//     const h1x = await blandHash(x);
//     const hx1 = await blandHash(x1);
//     const h1x1 = await blandHash(x1);
//     expect(hx.encoded == h1x.encoded).toBe(true);
//     expect(hx1.encoded == h1x1.encoded).toBe(true);
//     expect(hx.encoded != hx1.encoded).toBe(false);
// });
