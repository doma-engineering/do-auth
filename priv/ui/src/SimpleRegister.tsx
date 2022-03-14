import { useEffect, useState } from 'react';

function SimpleRegister() {
    const [dyn,] = useState('');

    useEffect(() => {
        if (!dyn) {
        }
    }, []);

    if (dyn) {
        return <span>{dyn}</span>;
    } else {
        return <span>loading doauth</span>;
    }
}

export default SimpleRegister;
