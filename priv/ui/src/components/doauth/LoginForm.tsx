import { useAtom } from 'jotai';
import { FormEvent } from 'react';
import { objectToView } from '../../atoms/devHelpsComponents';
import { keyPairSessionStorage } from '../../atoms/password';
import { mkCredential } from '../../doauth/credential';
import { Cannable, deriveSigningKeypair, mainKey } from '../../doauth/crypto';
import FormInputLine from '../form/FormInputLine';

function LoginForm() {
    const [, displayCredential] = useAtom(objectToView);
    const [, saveKeyPair] = useAtom(keyPairSessionStorage);

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

        // Make submit content
        const mainKeyValue = await mainKey(password.value, {
            saltOverride: email.value.toLowerCase(),
        });
        const keyPair = await deriveSigningKeypair(mainKeyValue, 1);
        const payload: Record<string, Cannable> = {
            email: email.value,
            nickname: nickname.value,
        };
        const credential = await mkCredential(keyPair, payload);
        saveKeyPair(keyPair);

        // Make submit
        await fetch('http://localhost:8111/echo', {
            method: 'POST',
            body: JSON.stringify(credential),
        })
            .then((response) => response.json())
            .then((data) => {
                const body = JSON.parse(data.body);
                displayCredential(body);
                console.log(data);
            });
    };

    return (
        <form
            onSubmit={(ev) => onSubmit(ev)}
            className="plane flex flex-col space-y-3"
        >
            <FormInputLine
                name="nickname"
                label="Nickname: "
                inputProps={{ autoComplete: 'off', required: true }}
            />
            <FormInputLine
                name="email"
                label="Email: "
                inputProps={{ type: 'email', required: false }}
            />
            <FormInputLine
                name="password"
                label="Password: "
                inputProps={{ type: 'password', required: false }}
            />
            <div className="flex justify-end">
                <button type="submit" className="button-primary">
                    submit
                </button>
            </div>
        </form>
    );
}

export default LoginForm;
