/// <reference path="../../node_modules/@types/mocha/index.d.ts" />

import expect = require('expect.js');

import { App, PostObj } from '../../src/';
import { ObjType } from '@threadtime/threadtime-common';
import {TestPortNumber} from "../TestPortNumber";

describe('PostObj', () => {
    let app: App;
    let postObj: PostObj;

    beforeEach((done) => {
        app = new App({...(App.DEFAULT_CONFIG), port: TestPortNumber()});
        app.start().then(() => done());
    });

    afterEach(() => app.stop());

    describe('constructor', () => {
        it('sets the type to Post', () => {
            postObj = new PostObj(app);
            expect(postObj.type).to.equal(ObjType.Post);
        });
    });
});
