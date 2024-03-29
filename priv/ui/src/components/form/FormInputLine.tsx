import { ChangeEvent, FocusEvent, HTMLProps, ReactNode, useState } from 'react';

function FormInputLine({
    name,
    label,
    errorMessage,
    inputProps,
}: {
    name: string;
    label: ReactNode;
    errorMessage?: ReactNode;
    inputProps?: HTMLProps<HTMLInputElement>;
}) {
    const [touched, setTouched] = useState(false);
    const [invalid, setInvalid] = useState(false);

    const handleCheckInvalid = (inputElement: HTMLInputElement) => {
        if (
            typeof inputProps === 'object' &&
            typeof inputProps.pattern === 'string'
        ) {
            const regex = new RegExp(inputProps.pattern);
            setInvalid(!regex.test(inputElement.value));
        } else {
            if (inputProps?.required)
                setInvalid(inputElement.value.length === 0);
        }
    };

    // Make input props onBlur maybe.
    // Set touched.
    // Validates value.
    const handleOnBlur = (e: FocusEvent<HTMLInputElement, Element>) => {
        if (
            typeof inputProps === 'object' &&
            typeof inputProps.onBlur === 'function'
        )
            inputProps.onBlur(e);
        setTouched(true);
        handleCheckInvalid(e.currentTarget);
    };

    // Make input props onChange maybe.
    // Validates value.
    const handleOnChange = (e: ChangeEvent<HTMLInputElement>) => {
        if (
            typeof inputProps === 'object' &&
            typeof inputProps.onChange === 'function'
        )
            inputProps.onChange(e);
        handleCheckInvalid(e.target);
    };

    return (
        <div>
            <label className="flex justify-between">
                <span className="pr-2">{label}</span>
                <input
                    name={name}
                    {...inputProps}
                    className={`${inputProps?.className}
                                ${
                                    touched
                                        ? 'invalid:border invalid:border-error'
                                        : ''
                                }`}
                    onBlur={handleOnBlur}
                    onChange={handleOnChange}
                />
            </label>
            <div
                className={`text-error w-full text-center text-sm
                            ${touched && invalid ? '' : 'hidden'}`}
            >
                {errorMessage}
            </div>
        </div>
    );
}

export default FormInputLine;
