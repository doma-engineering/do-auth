import { useEffect, useState } from 'react';
import ensureDynLoaded from './doauthor_react';

function SimpleRegister() {
    const [dyn, setDyn] = useState('');

    useEffect(() => {
        if (!dyn) {
            ensureDynLoaded(dyn, setDyn);
        }
    }, []);

    if (dyn) {
        return <span>{dyn}</span>;
    } else {
        return <span>loading doauth</span>;
    }
}

export default SimpleRegister;
