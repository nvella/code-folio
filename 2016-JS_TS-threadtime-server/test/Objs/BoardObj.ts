/// <reference path="../../node_modules/@types/mocha/index.d.ts" />

import expect = require('expect.js');

import { App, BoardObj } from '../../src/';
import { ObjType } from '@threadtime/threadtime-common';
import {TestPortNumber} from "../TestPortNumber";

describe('BoardObj', () => {
    let app: App;
    let boardObj: BoardObj;

    beforeEach((done) => {
        app = new App({...(App.DEFAULT_CONFIG), port: TestPortNumber()});
        app.start().then(() => done());
    });

    afterEach(() => app.stop());

    describe('constructor', () => {
        it('sets the type to Board', () => {
            boardObj = new BoardObj(app);
            expect(boardObj.type).to.equal(ObjType.Board);
        });
    });
});
