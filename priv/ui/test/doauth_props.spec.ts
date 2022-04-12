import sodium0 from 'libsodium-wrappers';
import { testProp, fc } from 'jest-fast-check';
import { test, expect } from '@jest/globals';
import { mkCredential, presentCredential } from '../src/doauth/credential';
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

/*
    iex(18)> DoAuth.Credential.present_credential_map(kp, cred_map, issuanceDate: tau1) |> Uptight.Result.from_ok() |> Jason.encode!(pretty: true) |> IO.puts
    {
    "issuanceDate": "2021-12-19T02:31:30Z",
    "issuer": "dW8Z2z2icecILIyAdrjaOqkurfC99ocFR87r9QX_mJQ=",
    "proof": {
        "signature": "RYa98wyKQ8Gl2GrtYVxUFXPs7m9PFL9wT09xv368dJzK9aJIJ8gZreiugOuKCLtljFex2QWH58Az79x99PyGAg==",
        "timestamp": "2021-12-19 04:05:50.471122Z",
        "verificationMethod": "dW8Z2z2icecILIyAdrjaOqkurfC99ocFR87r9QX_mJQ="
    },
    "verifiableCredential": {
        "@context": [],
        "credentialSubject": {
        "hello": "world"
        },
        "id": "5rQ5V1M3QzCCFOH_w1xu0ondNWLyn8sd4-p3-AiS3GXKLjO4J4BUWLM1xH-CfFcd-LPj-ys908SjHMa-WOq-AA==",
        "issuanceDate": "2021-08-17T22:49:56Z",
        "issuer": "dW8Z2z2icecILIyAdrjaOqkurfC99ocFR87r9QX_mJQ=",
        "proof": {
        "created": "2021-12-07T13:57:55.931383Z",
        "proofPurpose": "assertionMethod",
        "signature": "5rQ5V1M3QzCCFOH_w1xu0ondNWLyn8sd4-p3-AiS3GXKLjO4J4BUWLM1xH-CfFcd-LPj-ys908SjHMa-WOq-AA==",
        "type": "Libsodium2021",
        "verificationMethod": "dW8Z2z2icecILIyAdrjaOqkurfC99ocFR87r9QX_mJQ="
        },
        "type": []
    }
    }
*/
const presentationTarget = `{
    "issuanceDate": "2021-12-19T02:31:30Z",
    "issuer": "dW8Z2z2icecILIyAdrjaOqkurfC99ocFR87r9QX_mJQ=",
    "proof": {
      "signature": "RYa98wyKQ8Gl2GrtYVxUFXPs7m9PFL9wT09xv368dJzK9aJIJ8gZreiugOuKCLtljFex2QWH58Az79x99PyGAg==",
      "timestamp": "2021-12-19 04:05:50.471122Z",
      "verificationMethod": "dW8Z2z2icecILIyAdrjaOqkurfC99ocFR87r9QX_mJQ="
    },
    "verifiableCredential": {
      "@context": [],
      "credentialSubject": {
        "hello": "world"
      },
      "id": "5rQ5V1M3QzCCFOH_w1xu0ondNWLyn8sd4-p3-AiS3GXKLjO4J4BUWLM1xH-CfFcd-LPj-ys908SjHMa-WOq-AA==",
      "issuanceDate": "2021-08-17T22:49:56Z",
      "issuer": "dW8Z2z2icecILIyAdrjaOqkurfC99ocFR87r9QX_mJQ=",
      "proof": {
        "created": "2021-12-07T13:57:55.931383Z",
        "proofPurpose": "assertionMethod",
        "signature": "5rQ5V1M3QzCCFOH_w1xu0ondNWLyn8sd4-p3-AiS3GXKLjO4J4BUWLM1xH-CfFcd-LPj-ys908SjHMa-WOq-AA==",
        "type": "Libsodium2021",
        "verificationMethod": "dW8Z2z2icecILIyAdrjaOqkurfC99ocFR87r9QX_mJQ="
      },
      "type": []
    }
}`;

/*
    iex(19)> %{public: "dW8Z2z2icecILIyAdrjaOqkurfC99ocFR87r9QX_mJQ=", secret: "H9xUHnIAxdYuslQ8UULO8A0eXf6gH2ySEfo2-kdZZow32Nza1n_O_YdP4Qg7JuCbt8ieMOZkFypb-UbAWVLKCg=="} |> Witchcraft.Functor.map(fn x -> Uptight.Base.mk_url!(x).raw |> Uptight.Binary.new!() end) |> DoAuth.Credential.mk_credential!(%{"hello" => "world"}, issuanceDate: ~N[2021-08-17 22:49:56] |> DateTime.from_naive!("Etc/UTC")) |> Jason.encode!(pretty: true) |> IO.puts()
    {
    "@context": [],
    "credentialSubject": {
        "hello": "world"
    },
    "id": "5rQ5V1M3QzCCFOH_w1xu0ondNWLyn8sd4-p3-AiS3GXKLjO4J4BUWLM1xH-CfFcd-LPj-ys908SjHMa-WOq-AA==",
    "issuanceDate": "2021-08-17T22:49:56Z",
    "issuer": "dW8Z2z2icecILIyAdrjaOqkurfC99ocFR87r9QX_mJQ=",
    "proof": {
        "created": "2021-12-07T13:57:55.931383Z",
        "proofPurpose": "assertionMethod",
        "signature": "5rQ5V1M3QzCCFOH_w1xu0ondNWLyn8sd4-p3-AiS3GXKLjO4J4BUWLM1xH-CfFcd-LPj-ys908SjHMa-WOq-AA==",
        "type": "Libsodium2021",
        "verificationMethod": "dW8Z2z2icecILIyAdrjaOqkurfC99ocFR87r9QX_mJQ="
    },
    "type": []
    }
    :ok
*/
const credentialTarget = `{
    "@context": [],
    "credentialSubject": {
        "hello": "world"
    },
    "id": "5rQ5V1M3QzCCFOH_w1xu0ondNWLyn8sd4-p3-AiS3GXKLjO4J4BUWLM1xH-CfFcd-LPj-ys908SjHMa-WOq-AA==",
    "issuanceDate": "2021-08-17T22:49:56Z",
    "issuer": "dW8Z2z2icecILIyAdrjaOqkurfC99ocFR87r9QX_mJQ=",
    "proof": {
        "created": "2021-12-07T13:57:55.931383Z",
        "proofPurpose": "assertionMethod",
        "signature": "5rQ5V1M3QzCCFOH_w1xu0ondNWLyn8sd4-p3-AiS3GXKLjO4J4BUWLM1xH-CfFcd-LPj-ys908SjHMa-WOq-AA==",
        "type": "Libsodium2021",
        "verificationMethod": "dW8Z2z2icecILIyAdrjaOqkurfC99ocFR87r9QX_mJQ="
    },
    "type": []
}`;

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

test('verifiable credentials are compatible with Elixir implementation', async () => {
    const kp = {
        public: { encoded: 'dW8Z2z2icecILIyAdrjaOqkurfC99ocFR87r9QX_mJQ=' },
        secret: {
            encoded:
                'H9xUHnIAxdYuslQ8UULO8A0eXf6gH2ySEfo2-kdZZow32Nza1n_O_YdP4Qg7JuCbt8ieMOZkFypb-UbAWVLKCg==',
        },
    };
    const cred_ours = await mkCredential(
        kp,
        { hello: 'world' },
        { issuanceDate: '2021-08-17T22:49:56Z' }
    );
    const cred_ref = JSON.parse(credentialTarget);
    expect((cred_ours['proof'] as any)['signature']).toStrictEqual(
        (cred_ref['proof'] as any)['signature']
    );
});

test('verifiable presentations are compatible with Elixir implementation', async () => {
    const kp = {
        public: { encoded: 'dW8Z2z2icecILIyAdrjaOqkurfC99ocFR87r9QX_mJQ=' },
        secret: {
            encoded:
                'H9xUHnIAxdYuslQ8UULO8A0eXf6gH2ySEfo2-kdZZow32Nza1n_O_YdP4Qg7JuCbt8ieMOZkFypb-UbAWVLKCg==',
        },
    };
    const cred = JSON.parse(credentialTarget);
    const pres_ours = await presentCredential(kp, cred, {
        issuanceDate: '2021-12-19T02:31:30Z',
    });
    const pres_ref = JSON.parse(presentationTarget);
    const our_sig = (pres_ours['proof'] as any)['signature'];
    const ref_sig = (pres_ref['proof'] as any)['signature'];
    expect(our_sig).toStrictEqual(ref_sig);
});
