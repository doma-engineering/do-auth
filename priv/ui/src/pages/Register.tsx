import { useCallback, useState } from 'react';
import RegisterForm from '../components/doauth/RegisterForm';
import { useNavigate } from 'react-router-dom';

export type UserRegData = { email: string; password: string; nickname: string };

export default function RegisterPage() {
    const [completeRegForm, setCompleteRegForm] = useState(false);
    const [dataPersist, setUserData] = useState<UserRegData>({
        email: '',
        nickname: '',
        password: '',
    });

    const onCompleteForm = useCallback((user?: UserRegData) => {
        console.log(user);
        if (user !== undefined) setUserData(user!);
        setCompleteRegForm(true);
    }, []);

    const onCancelWaiting = useCallback(() => {
        setCompleteRegForm(false);
    }, []);

    return (
        <>
            {completeRegForm ? (
                <MailWaitingPage onCancelWaiting={onCancelWaiting} />
            ) : (
                <RegisterForm
                    onComplete={onCompleteForm}
                    defaultValue={dataPersist}
                />
            )}
        </>
    );
}

export function MailWaitingPage({
    onCancelWaiting,
}: {
    onCancelWaiting?: () => void;
}) {
    const navigate = useNavigate();
    const handleToRegister = () => {
        typeof onCancelWaiting === 'function'
            ? onCancelWaiting()
            : navigate('/register');
    };

    return (
        <>
            <p className="pt-12">Registry complete successful! </p>
            <p>
                <span className="font-bold underline">Check your E-mail</span>{' '}
                for receive confirmation link!{' '}
            </p>
            <p className="pt-8">
                If you don't receive mail check your inputs and try again.
            </p>
            <button className="button-primary my-3" onClick={handleToRegister}>
                Don't receive mail
            </button>
        </>
    );
}
