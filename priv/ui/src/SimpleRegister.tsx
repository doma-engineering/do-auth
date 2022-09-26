import { useAtom } from 'jotai';
import { ChangeEvent, FormEvent, useState } from 'react';
import { keyPairSessionStorage } from './atoms/password';
import FormInputLine from './components/form/FormInput';
import { deriveSigningKeypair, mainKey } from './doauth/crypto';

const bellowInput = (text: string | string[]) => (
    <div className="pt-1 flex flex-col items-end">
        {typeof text === 'string' ? (
            <div className="text-center w-[210px]">{text}</div>
        ) : (
            text.map((fragment, i) => (
                <div key={`err_frag_${i}`} className="text-center w-[210px]">
                    {fragment}
                </div>
            ))
        )}
    </div>
);

function SimpleRegister() {
    const [, saveKeyPair] = useAtom(keyPairSessionStorage);
    const [password, setPassword] = useState('');
    const handleChangePassword = (e: ChangeEvent<HTMLInputElement>) => {
        setPassword(e.target.value);
    };

    const onSubmit = async (event: FormEvent) => {
        // Disable page reload
        event.preventDefault();

        // Get input values
        // (event.target as HTMLFormElement).elements :
        // 0: fieldset :
        // 1: input    : nickname
        // 2: input    : email
        // 3: fieldset :
        // 4: input    : password
        // 5: input    : passwordConfirm
        // !! Indexes may be out of date, if markup changes !!
        const [nickname, email, password] = [
            1, // nickname index
            2, // email index
            4, // password index
        ].map(
            (index) =>
                (
                    (event.target as HTMLFormElement).elements[
                        index
                    ] as HTMLInputElement
                ).value
        );

        // Save password as key pair
        const mainKeyValue = await mainKey(password, {
            saltOverride: email.toLowerCase(),
        });
        const keyPair = await deriveSigningKeypair(mainKeyValue, 1);
        saveKeyPair(keyPair);

        // Make submit
        const queryReservationUrl = new URL(
            'http://localhost:8111/doauth/reserve'
        );
        queryReservationUrl.searchParams.append('email', email);
        queryReservationUrl.searchParams.append('nickname', nickname);
        await fetch(queryReservationUrl, {
            method: 'GET',
        });
    };

    return (
        <form onSubmit={(ev) => onSubmit(ev)} className="plane flex flex-col">
            <h1 className="text-xl text-center mb-5">Registration form</h1>
            <fieldset className="fieldset-lines-bt">
                <FormInputLine
                    label="Nickname:"
                    errorMessage={bellowInput([
                        'Please enter valid nickname;',
                        'use: a-Z, 0-9, -, _ or spaces.',
                    ])}
                    inputProps={{
                        type: 'text',
                        className: 'w-[210px]',
                        placeholder: 'John Doe',
                        pattern: '^[a-zA-Z\\s_\\-0-9]{1,50}$',
                        required: true,
                    }}
                />{' '}
                <FormInputLine
                    label="Email:"
                    errorMessage={bellowInput('Please enter valid email.')}
                    inputProps={{
                        type: 'email',
                        className: 'w-[210px]',
                        placeholder: 'example@example.com',
                        pattern:
                            '^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+.[a-zA-z]{2,3}$',
                        required: true,
                    }}
                />
            </fieldset>
            <fieldset className="fieldset-lines-b">
                <FormInputLine
                    label="Password:"
                    errorMessage={bellowInput(
                        'Password must be at least 8 digits.'
                    )}
                    inputProps={{
                        type: 'password',
                        className: 'w-[210px]',
                        placeholder: '••••••••',
                        pattern: '^.{8,}$',
                        onChange: handleChangePassword,
                        required: true,
                    }}
                />
                <FormInputLine
                    label="Confirm password:"
                    errorMessage={bellowInput("Password don't match.")}
                    inputProps={{
                        type: 'password',
                        className: 'w-[210px]',
                        placeholder: '••••••••',
                        pattern: password,
                        required: true,
                    }}
                />
            </fieldset>
            <fieldset className="pt-3 flex justify-between">
                <label>
                    <input type="checkbox" required />
                    <span className="pl-2 text-sm text-gray-300">
                        Agree to receive confirm
                    </span>
                </label>
                <button type="submit" className="button-primary">
                    submit
                </button>
            </fieldset>
        </form>
    );
}

export default SimpleRegister;
