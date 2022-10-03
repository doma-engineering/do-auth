import { useNavigate } from 'react-router-dom';

export default function MailWaitingPage({
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
                If you don't receive mail check your input's and try again.
            </p>
            <button className="button-primary my-3" onClick={handleToRegister}>
                Don't receive mail
            </button>
        </>
    );
}
