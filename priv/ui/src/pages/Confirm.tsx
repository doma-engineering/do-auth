import { useEffect, useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import LoginForm from '../components/doauth/LoginForm';

export default function ConfirmationPage() {
    const [searchParams] = useSearchParams();

    const [approved, setApproved] = useState(false);
    const [isInprogress, setInprogress] = useState(true);

    const [parameters, setParameters] = useState({ email: '', token: '' });

    useEffect(() => {
        // Get query params
        const email = searchParams.get('email');
        const token = searchParams.get('token');

        // Check is query valid ; valid => confirmation;
        if (email != null && token != null) {
            setParameters({ email, token });

            // make url for backend submit
            const queryReservationUrl = new URL(
                'http://localhost:8111/doauth/confirm'
            );
            queryReservationUrl.searchParams.append('email', email);
            queryReservationUrl.searchParams.append('token', token);

            // make submit
            fetch(queryReservationUrl, {
                method: 'GET',
            }).then((response) => {
                setInprogress(false);
                if (response.ok) {
                    setApproved(() => true);
                } else {
                    setApproved((prev) => prev || false); // That bad, but second etc submit will got fail, so need make resistance
                }
            });
        } else {
            setInprogress(false);
        }
    }, [searchParams]);

    return (
        <>
            <div className="mt-16 mb-40">
                <Dev
                    email={parameters.email}
                    token={parameters.token}
                    isInprogress={isInprogress}
                    approved={approved}
                />
            </div>
            <div className="w-9/12 border-t-2 border-slate-400 my-3 h-screen mb-10 flex flex-col items-center">
                <div className="h-1/4" />
                <Success />
            </div>

            <div className="w-9/12 border-t-2 border-slate-400 my-3 h-screen flex flex-col items-center">
                <div className="h-1/4" />
                <Fail email={parameters.email} />
            </div>
        </>
    );
}

function Success() {
    return (
        <div className="mt-14 mb-10 flex flex-col items-center">
            <h1 className="text-2xl pb-6">Your E-mail was approved!</h1>
            <div className="flex">
                <div className=" text-2xl mx-4 flex flex-col items-end">
                    <p className="text-violet-500">Enter</p>
                    <p className="text-yellow-300">
                        <span className="text-violet-500">to</span> DoAuth
                    </p>
                    <p className="italic">now</p>
                </div>
                <LoginForm />
            </div>
        </div>
    );
}

function Fail({ email }: { email: string }) {
    return (
        <>
            <div className="mt-8 text-2xl">Email confirmation term is out!</div>
            <div className="text-lg my-4 text-slate-300 border px-4 py-2">
                {email}
            </div>

            <button className="button-primary">Resend mail</button>
        </>
    );
}

function Dev({
    email,
    token,
    isInprogress,
    approved,
}: {
    email: string;
    token: string;
    isInprogress: boolean;
    approved: boolean;
}) {
    return (
        <div className="flex flex-col items-center">
            <div className="plane text-lg space-y-1 w-96 mb-10">
                <div className="flex justify-center overflow-hidden">
                    <div className="w-44 pr-1 text-right">Your email: </div>
                    <div className="w-44 pl-1 text-left text-green-500 font-bold">
                        {formatEmail(email)}
                    </div>
                </div>
                <div className="flex justify-center">
                    <div className="w-44 pr-1 text-right">Your token: </div>
                    <div className="w-44 pl-1 text-left text-green-500 font-bold">
                        {token}
                    </div>
                </div>
                <div className="flex justify-center">
                    <div className="w-44 pr-1 text-right">Verification: </div>
                    <div className="w-44 pl-1 text-left text-green-500 font-bold">
                        {displayStage(isInprogress, approved)}
                    </div>
                </div>
            </div>
            {approved ? (
                <>
                    <Link
                        className="button-primary mt-3 block w-96 text-center"
                        to={'/login'}
                    >
                        Login
                    </Link>
                </>
            ) : null}
            <p className="pt-3 text-center">
                <span className="font-bold text-error">[DEV]</span> There should
                be different page, but that you can see details!
            </p>
            <p>
                Future should stay message: "All good, you can entry" or display
                error{' '}
            </p>
            <p className="pt-2">
                <span className="font-bold text-error">[DEV]</span> Fragments
                below don't works, and now can't do that.
            </p>
        </div>
    );
}

// ------------------ Helps functions --------------------

function displayStage(inprogress: boolean, approved: boolean) {
    if (inprogress)
        return <div className="text-violet-500 font-bold">in progress</div>;
    if (approved)
        return <div className="text-green-500 font-bold">complete</div>;
    return <div className="text-red-500 font-bold">failed</div>;
}

const formatEmail = (email: string) =>
    email.length > 14 ? `${email.slice(0, 14)}...` : email;
