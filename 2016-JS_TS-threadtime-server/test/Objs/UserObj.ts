/// <reference path="../../node_modules/@types/mocha/index.d.ts" />

import expect = require('expect.js');

import { App, UserObj } from '../../src/';
import { ObjType } from '@threadtime/threadtime-common';
import {TestPortNumber} from "../TestPortNumber";

describe('UserObj', () => {
    let app: App;
    let userObj: UserObj;

    beforeEach((done) => {
        app = new App({...(App.DEFAULT_CONFIG), port: TestPortNumber()});
        app.start().then(() => done());
    });

    afterEach(() => app.stop());

    describe('constructor', () => {
        it('sets the type to User', () => {
            userObj = new UserObj(app);
            expect(userObj.type).to.equal(ObjType.User);
        });
    });
});
