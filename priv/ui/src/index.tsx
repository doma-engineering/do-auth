import React from 'react';
import ReactDOM from 'react-dom';
import './index.css';

//import reportWebVitals from './reportWebVitals';

import('./' + process.env.REACT_APP_ENTRY!).then(App => {
  const APP_DEFAULT = App.default;
  ReactDOM.render(
    <React.StrictMode>
      <APP_DEFAULT />
    </React.StrictMode>,
    document.getElementById('root')
  )
});

// // If you want to start measuring performance in your app, pass a function
// // to log results (for example: reportWebVitals(console.log))
// // or send to an analytics endpoint. Learn more: https://bit.ly/CRA-vitals
// reportWebVitals();
