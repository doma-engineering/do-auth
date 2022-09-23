import { atom } from 'jotai';

export const atomWithSessionStorage = <T>(key: string, initialValue: T) => {
    const getInitialValue = (): T => {
        const item = sessionStorage.getItem(key);
        if (item !== null) return JSON.parse(item);
        return initialValue;
    };
    const baseAtom = atom<T>(getInitialValue());
    const derivedAtom = atom(
        (get): T => get(baseAtom),
        (get, set, update: T | ((previous: T) => T)) => {
            const nextValue: T =
                update instanceof Function ? update(get(baseAtom)) : update;
            set(baseAtom, nextValue);
            sessionStorage.setItem(key, JSON.stringify(nextValue));
        }
    );
    return derivedAtom;
};

export const atomWithLocalStorage = <T>(key: string, initialValue: T) => {
    const getInitialValue = (): T => {
        const item = localStorage.getItem(key);
        if (item !== null) {
            return JSON.parse(item);
        }
        return initialValue;
    };
    const baseAtom = atom<T>(getInitialValue());
    const derivedAtom = atom(
        (get): T => get(baseAtom),
        (get, set, update: T | ((previous: T) => T)) => {
            const nextValue: T =
                update instanceof Function ? update(get(baseAtom)) : update;
            set(baseAtom, nextValue);
            localStorage.setItem(key, JSON.stringify(nextValue));
        }
    );
    return derivedAtom;
};
