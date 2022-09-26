import { useAtom } from 'jotai';
import { ChangeEvent, FormEvent, useState } from 'react';
import { makeKeypairAndSaveToSessionStorage } from '../../atoms/password';
import FormInputLine from '../form/FormInputLine';

function SimpleRegister({ name }: { name: string }) {
    const [, saveKeyPair] = useAtom(makeKeypairAndSaveToSessionStorage);
    const [password, setPassword] = useState('');
    const handleChangePassword = (e: ChangeEvent<HTMLInputElement>) => {
        setPassword(e.target.value);
    };

    const onSubmit = async (event: FormEvent) => {
        event.preventDefault(); // Disable page reload
        const [nickname, email, password] = getInputValues(
            event.target as HTMLFormElement,
            name,
            ['nickname', 'email', 'password']
        );
        saveKeyPair({ password, email }); // Save password as key pair to Session Storage
        makeSubmit(email, nickname);
    };

    return (
        <form onSubmit={(ev) => onSubmit(ev)} className="plane flex flex-col">
            <h1 className="text-xl text-center mb-5">Registration form</h1>
            <fieldset className="fieldset-lines-bt">
                <FormInputLine
                    name={`${name}:nickname`}
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
                />
                <FormInputLine
                    name={`${name}:email`}
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
                    name={`${name}:password`}
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
                    name={`${name}:passwordConfirm`}
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

// --------------------- Helps functions ---------------------

// Centred the error text below input for a 'error' in FormInputLine arguments,
// based on the inputProps have a className with w-[210px]
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

// inputs name's should be  "${formName}:${fieldName}"
// formName - is metaphoric, more often formName is higher component name, need for make uniq names for the components duplicate.
const getInputValues = (
    form: HTMLFormElement,
    formName: string,
    fields: string[]
) =>
    fields
        .map((fieldName) => `${formName}${fieldName}`)
        .map(
            (elementName) =>
                (form.elements.namedItem(elementName) as HTMLInputElement).value
        );

// Call mail reserve endpoint, that should send confirmation mail on email.
const makeSubmit = async (email: string, nickname: string) => {
    const queryReservationUrl = new URL('http://localhost:8111/doauth/reserve');
    queryReservationUrl.searchParams.append('email', email);
    queryReservationUrl.searchParams.append('nickname', nickname);
    fetch(queryReservationUrl, {
        method: 'GET',
    });
};
