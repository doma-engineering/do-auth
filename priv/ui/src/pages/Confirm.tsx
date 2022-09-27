import { useAtom } from 'jotai';
import { useEffect, useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { objectToView } from '../atoms/devHelpsComponents';
import JsonView from '../components/devHelps/JsonView';

enum VerificationStage {
    progress,
    successful,
    failed,
}

export default function ConfirmationPage() {
    const [searchParams] = useSearchParams();

    const [isValidQuery, setValidQuery] = useState(true);
    const [verification, setVerification] = useState(
        VerificationStage.progress
    );
    const [parameters, setParameters] = useState({ email: '', token: '' });

    const [, showErrorObject] = useAtom(objectToView);

    useEffect(() => {
        // Get query params
        const email = searchParams.get('email');
        const token = searchParams.get('token');

        // Check is query valid ; valid => do confirmation;
        if (email != null && token != null) {
            setValidQuery(true);
            setParameters({ email, token });

            // make url for backend
            const queryReservationUrl = new URL(
                'http://localhost:8111/doauth/confirm'
            );
            queryReservationUrl.searchParams.append('email', email);
            queryReservationUrl.searchParams.append('token', token);

            // make submit |> unpack result
            const fetchData = async () =>
                fetch(queryReservationUrl, {
                    method: 'GET',
                })
                    .then((response) => response.json())
                    .then((data) => {
                        console.log(data);
                        if (typeof data.error === 'string') {
                            //response is error
                            setVerification(VerificationStage.failed);
                            showErrorObject({
                                ...data,
                            });
                        } else {
                            //response is success
                            setVerification(VerificationStage.successful);
                        }
                    });
            fetchData();
        } else {
            setValidQuery(false);
        }
    }, [searchParams]);

    return isValidQuery ? (
        <>
            <div className="plane text-lg space-y-1 w-96">
                <p>
                    Your email:{' '}
                    <span className="text-green-500 font-bold ">
                        {parameters.email}
                    </span>
                </p>
                <p>
                    Your token:{' '}
                    <span className="text-green-500 font-bold">
                        {parameters.token}
                    </span>
                </p>
                <p>Verification: {displayStage(verification)}</p>
            </div>
            {verification === VerificationStage.successful ? (
                <Link
                    className="button-primary mt-3 w-96 text-center"
                    to={'/login'}
                >
                    Login
                </Link>
            ) : null}
            {verification === VerificationStage.failed ? (
                <JsonView className="mt-3 w-96" header="Response:" />
            ) : null}
        </>
    ) : (
        <div>
            <p>Your link is broken.</p>
        </div>
    );
}

// ------------------ Helps functions --------------------

function displayStage(stage: VerificationStage) {
    switch (stage) {
        case VerificationStage.progress:
            return (
                <span className="text-violet-500 font-bold">in progress</span>
            );
        case VerificationStage.successful:
            return <span className="text-green-500 font-bold">complete</span>;
        case VerificationStage.failed:
            return <span className="text-red-500 font-bold">failed</span>;
    }
}
