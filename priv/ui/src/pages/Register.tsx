import { useCallback, useState } from 'react';
import RegisterForm from '../components/doauth/RegisterForm';
import MailWaitingPage from './MailWaiting';

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
