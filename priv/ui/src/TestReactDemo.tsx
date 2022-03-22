import { useEffect, useState } from "react";

function TestReactDemo() {
    const [label, setLabel] = useState('Loading...');
    useEffect(() => {
        setTimeout(() => setLabel('Loaded!'), 600);
    }, [])
    return (
        <h1>{label}</h1>
    )
}

export default TestReactDemo;
