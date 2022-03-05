#!/usr/bin/env -S node --require tsm

import fs, { chown } from 'fs';
import child_process from 'child_process';

const main = () => {
    const userSuppliedArgs = parseArgs();
    const listing = fs.readdirSync('./src');
    const entryPoints = (listing.reduce((acc, x) => {
        if (isTsxEntry(x)) {
            return [x, ...acc];
        }
        return acc;
    }, []));
    if (userSuppliedArgs.length === 0 || !entryPoints.includes(userSuppliedArgs[0])) {
        return console.log(
            "Please supply one of the following entry points:", entryPoints
        );
    }
    const ph = child_process.spawn('npm', ['start'], { env: { ...process.env, REACT_APP_ENTRY: userSuppliedArgs[0] } });
    ph.stdout.on('data', (x) => console.log(x.toString()));
}

const parseArgs = (): string[] => {
    return process.argv.slice(2);
}

const startsWithUpcase = (w: string) => w[0] === w[0].toUpperCase();

const isTsxEntry = (x: string): boolean => {
    const bits = x.split('.');
    return bits.length === 2 && startsWithUpcase(bits[0]) && bits[1] === 'tsx';
}

main();
