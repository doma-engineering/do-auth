import React from 'react';
import { createRoot } from 'react-dom/client';
import './index.css';

//import reportWebVitals from './reportWebVitals';

import('./' + (process.env.REACT_APP_ENTRY ?? 'Router.tsx')).then((App) => {
    const APP_DEFAULT = App.default;
    const container = document.getElementById('root');
    const root = createRoot(container!);
    root.render(
        <React.StrictMode>
            <APP_DEFAULT />
        </React.StrictMode>
    );
});

// // If you want to start measuring performance in your app, pass a function
// // to log results (for example: reportWebVitals(console.log))
// // or send to an analytics endpoint. Learn more: https://bit.ly/CRA-vitals
// reportWebVitals();
