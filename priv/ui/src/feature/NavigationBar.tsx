import { Link } from 'react-router-dom';

function NavigationBar() {
    return (
        <nav className="flex my-8 space-x-1 text-blue-500 underline decoration-blue-500">
            <Link
                className="w-20 text-center rounded-md px-2 py-0 border border-blue-500"
                to="login"
                reloadDocument={false}
            >
                Login
            </Link>
            <Link
                className="w-20 text-center rounded-md px-2 py-0 border border-blue-500"
                to="register"
                reloadDocument={false}
            >
                Register
            </Link>
        </nav>
    );
}
export default NavigationBar;
