import assert, { equal } from 'assert/strict';

const WDIO_URL = process.env.WDIO_URL || 'localhost';

const punch = '\n================\n';

describe('wdio', () => {
    it('runs tests', async () => {
        return true;
    });
    it('has access to browser object', async () => {
        assert(typeof browser === 'object');
        try {
            await browser.url(`http://${WDIO_URL}:3000`);
        } catch (e) {
            equal(e.name, 'unknown error'); // Nice meme, wdio! Love it when things get forgotten.
            // That said, if url isn't in browser and isn't a funciton, we'll get a TypeError, so this test isn't completely useless.

            // assert(JSON.stringify(e).includes('net::ERR_CONNECTION_REFUSED'));
        }
    });
    it('can test a react app', async () => {
        await browser.url(`http://${WDIO_URL}:3000`);
        const loadingComponents = await browser.react$$('TestReactDemo');
        console.warn(
            punch,
            JSON.stringify(loadingComponents),
            loadingComponents.length,
            punch,
            await $('#root').getHTML(),
            punch
        );
        equal(loadingComponents.length, 1);
        // TODO: https://github.com/webdriverio/wdio-wait-for
    });
});
