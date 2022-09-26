import JsonView from '../components/devHelps/JsonView';
import SimpleLogin from '../components/doauth/SimpleLogin';

function LoginPage() {
    return (
        <div className="flex justify-center">
            <div className="w-[38rem] flex justify-end">
                <div>
                    <SimpleLogin />
                </div>
            </div>
            <JsonView header="Sended back credential:" className="ml-4" />
        </div>
    );
}
export default LoginPage;
