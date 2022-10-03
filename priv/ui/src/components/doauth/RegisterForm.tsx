import { ChangeEvent, FormEvent, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { UserRegData } from '../../pages/Register';
import FormInputLine from '../form/FormInputLine';

export default function RegisterForm({
    onComplete,
    defaultValue,
}: {
    onComplete?: (user: UserRegData) => void;
    defaultValue?: UserRegData;
}) {
    const navigate = useNavigate();
    const [password, setPassword] = useState(defaultValue?.password ?? '');

    const onSubmit = async (event: FormEvent) => {
        event.preventDefault(); // Disable page reload

        const { nickname, email, password } =
            event.target as typeof event.target & {
                nickname: { value: string };
                email: { value: string };
                password: { value: string };
            };

        makeSubmit(email.value, nickname.value);

        typeof onComplete === 'function'
            ? onComplete({
                  email: email.value,
                  nickname: nickname.value,
                  password: password.value,
              })
            : navigate('/waiting');
    };

    return (
        <form onSubmit={(ev) => onSubmit(ev)} className="plane flex flex-col">
            <h1 className="text-xl text-center mb-5">Registration form</h1>
            <fieldset className="fieldset-lines-bt">
                <FormInputLine
                    name="nickname"
                    label="Nickname:"
                    errorMessage={bellowInput([
                        'Please enter valid nickname;',
                        'use: a-Z, 0-9, -, _ or spaces.',
                    ])}
                    inputProps={{
                        type: 'text',
                        className: 'w-[210px]',
                        placeholder: 'John Doe',
                        defaultValue: defaultValue?.nickname,
                        autoComplete: 'off',
                        pattern: '^[a-zA-Z\\s_\\-0-9]{1,50}$',
                        required: true,
                    }}
                />
                <FormInputLine
                    name="email"
                    label="Email:"
                    errorMessage={bellowInput('Please enter valid email.')}
                    inputProps={{
                        type: 'email',
                        className: 'w-[210px]',
                        placeholder: 'example@example.com',
                        defaultValue: defaultValue?.email,
                        required: true,
                    }}
                />
            </fieldset>
            <fieldset className="fieldset-lines-b">
                <FormInputLine
                    name="password"
                    label="Password:"
                    errorMessage={bellowInput(
                        'Password must be at least 3 digits.'
                    )}
                    inputProps={{
                        type: 'password',
                        className: 'w-[210px]',
                        placeholder: '••••••••',
                        defaultValue: defaultValue?.password,
                        pattern: '^.{3,}$',
                        onChange: (e: ChangeEvent<HTMLInputElement>) =>
                            setPassword(e.target.value),
                        required: true,
                    }}
                />
                <FormInputLine
                    name="passwordConfirm"
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

// Call mail reserve endpoint, that should send confirmation mail on email.
const makeSubmit = async (email: string, nickname: string) => {
    const queryReservationUrl = new URL('http://localhost:8111/doauth/reserve');
    queryReservationUrl.searchParams.append('email', email);
    queryReservationUrl.searchParams.append('nickname', nickname);
    fetch(queryReservationUrl, {
        method: 'GET',
    });
};
