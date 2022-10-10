import { useAtom } from 'jotai';
import { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import JsonView from '../components/devHelps/JsonView';
import { objectToView } from '../atoms/devHelpsComponents';
import LoginForm from '../components/doauth/LoginForm';

enum ErrorType {
    TermOut,
    WrongEmailOrToken,
    MissingEmailOrToken,
}

export default function ConfirmationPage() {
    const [searchParams] = useSearchParams();

    const [approved, setApproved] = useState(false);
    const [isInprogress, setInprogress] = useState(true);

    const [errorType, setErrorType] = useState<null | ErrorType>(null);
    const [, setError] = useAtom(objectToView);
    const [parameters, setParameters] = useState({ email: '', token: '' });

    useEffect(() => {
        // Get query params
        const email = searchParams.get('email');
        const token = searchParams.get('token');

        // Check is query valid ; valid => confirmation;
        if (email != null && token != null) {
            setParameters({ email, token });

            // make url for backend submit

            const queryConfirmUrl = new URL(document.URL);
            queryConfirmUrl.pathname = '/doauth/confirm';
            queryConfirmUrl.searchParams.append('email', email);
            queryConfirmUrl.searchParams.append('token', token);

            // make submit
            fetch(queryConfirmUrl, {
                method: 'GET',
            }).then((response) => {
                setInprogress(false);
                if (response.ok) {
                    setApproved(() => true);
                } else {
                    setApproved(() => false);
                    if (response.status === 404) {
                        setErrorType(ErrorType.TermOut);
                    } else {
                        setErrorType(ErrorType.WrongEmailOrToken);
                        response.json().then((data) => {
                            setError(data);
                        });
                    }
                }
            });
        } else {
            setInprogress(false);
            setErrorType(ErrorType.MissingEmailOrToken);
            setParameters({ email: email ?? '', token: token ?? '' });
        }
    }, [searchParams]);

    return (
        <>
            {isInprogress ? (
                <Loading />
            ) : approved ? (
                <Success />
            ) : (
                <Fail errorType={errorType} parameters={parameters} />
            )}
        </>
    );
}

function Loading() {
    return <div>Loading...</div>;
}

function Success() {
    return (
        <div className="mt-14 mb-10 flex flex-col items-center">
            <h1 className="text-2xl pb-6">Your E-mail was approved!</h1>
            <div className="flex">
                <LoginForm />
            </div>
        </div>
    );
}

function Fail({
    errorType,
    parameters,
}: {
    errorType: ErrorType | null;
    parameters: { email: string; token: string };
}) {
    switch (errorType) {
        case ErrorType.TermOut:
            return <TermOut parameters={parameters} />;
        case ErrorType.WrongEmailOrToken:
            return <WrongEmailOrToken />;
        case ErrorType.MissingEmailOrToken:
            return <MissingEmailOrToken />;
    }
    return <></>;
}

function TermOut({
    parameters,
}: {
    parameters: { email: string; token: string };
}) {
    return (
        <>
            <div className="mt-14 text-2xl">
                Email confirmation term is out!
            </div>
            <div className="text-lg my-4 text-slate-300 border px-4 py-2">
                {parameters.email}
            </div>

            <button className="button-primary" disabled>
                Resend mail
            </button>
        </>
    );
}

function WrongEmailOrToken() {
    return (
        <>
            <div className="mt-14 text-2xl mb-4 text-left">
                <p className="text-center">Used wrong Email or token!</p>
                <MoreDetail />
                <div className="plane mt-10 text-base">
                    <p className="">For solve this you can try:</p>
                    <ul className="list-decimal">
                        <li className="pl-2 ml-5">
                            use button from accepting mail again,
                        </li>
                        <li className="pl-2 ml-5">
                            try get other token by E-mail,
                        </li>
                        <li className="pl-2 ml-5">
                            or register with other E-mail.
                        </li>
                    </ul>
                    <div className="flex justify-center space-x-3 text-sm mt-3">
                        <button className="button-primary" disabled>
                            Get new Token
                        </button>
                        <a href="/register" className="button-primary">
                            Go to Registry
                        </a>
                    </div>
                </div>
            </div>
        </>
    );
}

function MissingEmailOrToken() {
    return (
        <p className="mt-14 text-center text-2xl">
            In confirmation link missed token or e-mail.
        </p>
    );
}

function MoreDetail() {
    const [details, setDetails] = useState(false);
    const handleDetailsClick = () => setDetails((prev) => !prev);
    return (
        <>
            <div className="text-base flex justify-center">
                <button
                    className="button-secondary mt-4"
                    onClick={handleDetailsClick}
                >
                    {details ? 'hide details' : 'see details'}
                </button>
            </div>
            {details ? (
                <JsonView className="text-base w-96 mt-2" header="Problem:" />
            ) : null}
        </>
    );
}
