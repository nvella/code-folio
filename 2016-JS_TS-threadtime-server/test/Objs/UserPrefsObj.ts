/// <reference path="../../node_modules/@types/mocha/index.d.ts" />

import expect = require('expect.js');

import { App, UserPrefsObj } from '../../src/';
import { ObjType } from '@threadtime/threadtime-common';
import {TestPortNumber} from "../TestPortNumber";

describe('UserPrefsObj', () => {
    let app: App;
    let userPrefsObj: UserPrefsObj;

    beforeEach((done) => {
        app = new App({...(App.DEFAULT_CONFIG), port: TestPortNumber()});
        app.start().then(() => done());
    });

    afterEach(() => app.stop());

    describe('constructor', () => {
        it('sets the type to UserPrefs', () => {
            userPrefsObj = new UserPrefsObj(app);
            expect(userPrefsObj.type).to.equal(ObjType.UserPrefs);
        });
    });
});
