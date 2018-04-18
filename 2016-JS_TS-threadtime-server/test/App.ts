/// <reference path="../node_modules/@types/mocha/index.d.ts" />

import { expect } from 'chai';
import * as sioc from 'socket.io-client';
import * as async from 'async';
import * as _ from 'lodash';
import * as mongodb from 'mongodb';

import { App, Client, Obj } from '../src';
import { ObjType } from '@threadtime/threadtime-common';
import { DbMock } from "./DbMock";
import {TestPortNumber} from "./TestPortNumber";

describe('App', () => {
    let addr: string;
    let app: App;

    beforeEach(() => {
        let port = TestPortNumber();
        addr = `http://localhost:${port}`;
        app = new App({...(App.DEFAULT_CONFIG), port});
    });

    it('can add a Client to the list on connection', (done) => {
        async.waterfall([
            (cb: Function) => app.start().then(() => cb()).catch((err) => cb(err)),
            (cb: Function) => {
                let socket = sioc(addr);
                socket.on('connect', () => {
                    cb(null, socket);
                });
            },
            (socket: SocketIOClient.Socket, cb: (err?: any) => void) => {
                expect(app.clients).to.not.be.empty;
                socket.disconnect();
                app.stop().then(() => cb());
            }
        ], (err) => done(err));
    });

    it('can remove a Client from the list on disconnection', (done: Function) => {
        async.waterfall([
            (cb: Function) => app.start().then(() => cb()).catch((err) => cb(err)),
            (cb: Function) => {
                let socket: SocketIOClient.Socket = sioc(addr);
                socket.on('connect', () => cb(null, socket));
            },
            (socket: SocketIOClient.Socket, cb: Function) => {
                expect(app.clients).to.not.be.empty;
                socket.disconnect();
                setTimeout(() => cb(), 20);
            },
            (cb: Function) => {
                expect(app.clients).to.be.empty;
                app.stop().then(() => cb());
            }
        ], () => done());
    });

    it('can stop', (done: (err?: any) => void) => {
        async.series([
            (callback) => app.start().then(() => callback()),
            (callback) => app.stop().then(() => callback()),
            (callback) => {
                let socket: SocketIOClient.Socket = sioc(addr);
                socket.on('connect', () => {
                    throw Error('shouldn\'t be able to connect after the server has stopped.');
                });
                setTimeout(() => callback(), 10); // Wait for possible socket connection
                //setTimeout(() => done(), 10);
            }
        ], done);
    });

    describe('#start', () => {
        it('can start successfully', (done) => {
            async.series([
                (callback) => app.start().then(() => callback()),
                (callback) => app.stop().then(() => callback())
            ], done);
        });

        it('can connect the collections', (done) => {
            async.series([
                (callback) => app.start().then(() => callback()),
                (callback) => {
                    _.forEach(App.COLLECTIONS, (val: string) => {
                        expect(app.collections[val]).to.be.a('object');
                    });
                    callback();
                },
                (callback) => app.stop().then(() => callback())
            ], done);
        });
    });

    describe('#obj', () => {
        let dbMock: DbMock;

        beforeEach((done) => {
            dbMock = new DbMock(app);
            app.start().then(() => dbMock.run()).then(() => done());
        });

        afterEach(() => app.stop());

        it('can return an Obj from the database', (done) => {
            app.obj(dbMock.fixture[0]._id).then((obj: Obj) => {
                expect(obj._id).to.equal(dbMock.fixture[0]._id);
                expect(obj.ownerId).to.equal(dbMock.fixture[0].ownerId);
                done();
            }).catch((err) => done(err));
        });

        it('can return an error if Obj is not found', (done) => {
            app.obj('INVALID')
                .then((obj: Obj) => done(new Error('object should not have loaded')))
                .catch(() => done());
        });
    });

    describe('#collectObjs', () => {
        let dbMock: DbMock;

        beforeEach((done) => {
            dbMock = new DbMock(app);
            app.start().then(() => dbMock.run()).then(() => done());
        });

        afterEach(() => app.stop());

        it('it can collect the objects specified only, zero levels no children', (done) => {
            let ids = [`${ObjType.Board}_TEST1`, `${ObjType.Board}_TEST5`];
            app.collectObjs(ids, 0).then((objs: Obj[]) => {
                expect(objs.map((obj: Obj) => obj._id)).to.include.members(ids);
                expect(objs.length).to.equal(ids.length);
                done();
            }).catch((err) => done(err));
        });

        it('it can collect the objects specified and their children to one level', (done) => {
            let ids = [`${ObjType.Board}_TEST1`, `${ObjType.Board}_TEST5`];
            let childIds: string[] = [`${ObjType.Board}_TEST2`];
            app.collectObjs(ids, 1).then((objs: Obj[]) => {
                expect(objs.map((obj: Obj) => obj._id)).to.include.members(ids.concat(childIds));
                expect(objs.length).to.equal(ids.length + childIds.length);
                done();
            }).catch((err) => done(err));
        });

        it('it can collect the objects specified and their children to two levels', (done) => {
            let ids = [`${ObjType.Board}_TEST1`, `${ObjType.Board}_TEST5`];
            let childIds: string[] = [`${ObjType.Board}_TEST2`, `${ObjType.Board}_TEST3`, `${ObjType.Board}_TEST4`];
            app.collectObjs(ids, 2).then((objs: Obj[]) => {
                expect(objs.map((obj: Obj) => obj._id)).to.include.members(ids.concat(childIds));
                expect(objs.length).to.equal(ids.length + childIds.length);
                done();
            }).catch((err) => done(err));
        });

        it('it can collect the objects specified, their children and owners to two levels', (done) => {
            let ids = [`${ObjType.Board}_TEST1`, `${ObjType.Board}_TEST5`];
            let childIds: string[] = [`${ObjType.Board}_TEST2`, `${ObjType.Board}_TEST3`, `${ObjType.Board}_TEST4`, `${ObjType.User}_USER1`];
            app.collectObjs(ids, 2, [], true).then((objs: Obj[]) => {
                expect(objs.map((obj: Obj) => obj._id)).to.include.members(ids.concat(childIds));
                expect(objs.length).to.equal(ids.length + childIds.length);
                done();
            }).catch((err) => done(err));
        });

        it('it can correctly limit the amount of Objs returned at each level', async () => {
            let ids = [`${ObjType.Board}_TEST1`, `${ObjType.Board}_TEST5`];
            let childIds: string[] = [`${ObjType.Board}_TEST2`, `${ObjType.Board}_TEST4`];
            let objs = await app.collectObjs(ids, 2, [null, 1]);

            expect(objs.map((obj: Obj) => obj._id)).to.include.members(ids.concat(childIds));
            expect(objs.length).to.equal(ids.length + childIds.length);
        });
    });
});