import { useAtom } from 'jotai';
import { FormEvent } from 'react';
import { objectToView } from './atoms/feature';
import { mkCredential } from './doauth/credential';
import { Cannable, deriveSigningKeypair, mainKey } from './doauth/crypto';

function SimpleLogin() {
    const [, displayCredential] = useAtom(objectToView);

    const onSubmit = async (event: FormEvent) => {
        // Disable page reload
        event.preventDefault();

        // Get input values
        const { nickname, email, password } =
            event.target as typeof event.target & {
                nickname: { value: string };
                email: { value: string };
                password: { value: string };
            };

        const mainKeyValue = await mainKey(
            password.value,
            {
                saltOverride: email.value,
            },
            'prefer rewrite'
        );
        const keyPair = await deriveSigningKeypair(mainKeyValue, 5);
        const payload: Record<string, Cannable> = {
            email: email.value,
            nickname: nickname.value,
        };
        const credential = await mkCredential(keyPair, payload);

        await fetch('http://localhost:8111/echo', {
            method: 'POST',
            body: JSON.stringify(credential),
        })
            .then((response) => response.json())
            .then((data) => {
                const body = JSON.parse(data.body);
                displayCredential(body);
                console.log(body);
            });
    };

    return (
        <form
            onSubmit={(ev) => onSubmit(ev)}
            className="flex flex-col bg-slate-700 py-3 px-6 rounded shadow-md shadow-slate-900"
        >
            <fieldset className="flex justify-between pb-3">
                <label htmlFor="nickname" className="pr-2">
                    Nickname:
                </label>
                <input
                    id="nickname"
                    type="text"
                    className="bg-slate-900 p-1"
                    required
                />
            </fieldset>
            <fieldset className="flex justify-between pb-3">
                <label htmlFor="email" className="pr-2">
                    Email:
                </label>
                <input
                    id="email"
                    type="text"
                    className="bg-slate-900 p-1"
                    required
                />
            </fieldset>
            <fieldset className="flex justify-between pb-3">
                <label htmlFor="password" className="pr-2">
                    Password:
                </label>
                <input
                    id="password"
                    type="text"
                    className="bg-slate-900 p-1"
                    required
                />
            </fieldset>
            <div className="flex justify-end">
                <button
                    type="submit"
                    className="bg-blue-900 px-3 py-1 rounded hover:bg-blue-800 shadow-md shadow-slate-800 active:shadow-inner"
                >
                    submit
                </button>
            </div>
        </form>
    );
}

export default SimpleLogin;
