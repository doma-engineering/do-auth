import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import NavigationBar from './feature/NavigationBar';
import LoginPage from './pages/Login';
import SimpleRegister from './SimpleRegister';

function Router() {
    return (
        <div className="bg-slate-800 text-stone-200 max-w-screen min-h-screen flex flex-col items-center">
            <BrowserRouter>
                <h1 className="flex justify-center pt-20 text-3xl">
                    Welcome to ZeroHR
                </h1>
                <NavigationBar />
                <Routes>
                    <Route path="/" element={<Navigate to="/register" />} />
                    <Route path="/login" element={<LoginPage />} />
                    <Route path="/register" element={<SimpleRegister />} />
                    <Route
                        path="*"
                        element={
                            <div className="w-full h-full flex justify-center items-center text-6xl">
                                404
                            </div>
                        }
                    />
                </Routes>
            </BrowserRouter>
        </div>
    );
}
export default Router;
