import { App } from './';

let app = new App();
app.start().catch((err: Error) => {
    console.error(`Error in start: ${err.stack}`)
});