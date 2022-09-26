import { Link } from 'react-router-dom';

function NavigationBar() {
    return (
        <nav className="flex my-8 space-x-1">
            <Link
                className="w-20 button-secondary"
                to="login"
                reloadDocument={false}
            >
                Login
            </Link>
            <Link
                className="w-20 button-secondary"
                to="register"
                reloadDocument={false}
            >
                Register
            </Link>
        </nav>
    );
}
export default NavigationBar;
