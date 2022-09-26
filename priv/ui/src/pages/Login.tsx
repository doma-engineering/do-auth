import JsonView from '../components/devHelps/JsonView';
import LoginForm from '../components/doauth/LoginForm';

function LoginPage() {
    return (
        <div className="flex justify-center">
            <div className="w-[38rem] flex justify-end">
                <div>
                    <LoginForm />
                </div>
            </div>
            <JsonView header="Sended back credential:" className="ml-4" />
        </div>
    );
}
export default LoginPage;
