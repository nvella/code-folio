/// <reference path="../node_modules/@types/mocha/index.d.ts" />

import { expect } from 'chai';
import * as http from 'http';
import * as sio from 'socket.io';
import * as sioc from 'socket.io-client';
import * as shortid from 'shortid';
import * as async from 'async';
import * as _ from 'lodash';

import {
    NetHandler, AddSubscriptionMessage, ISubscription, RmSubscriptionMessage, MessageType, Message, ObjMessage, IObj,
    IBoard, RmObjMessage, ObjCacheStateMessage, IObjCacheState, ObjType, MessageField, DefaultObjPerms
} from '@threadtime/threadtime-common';
import { App, SubscriptionDispatch } from '../src';
import { DbMock } from './DbMock';
import { TestPortNumber } from './TestPortNumber';
import {Obj} from "../src/Objs/Obj";
import {ObjLookupByNameMessage} from "@threadtime/threadtime-common/dist/src/Messages/ObjLookupByNameMessage";

describe('SubscriptionDispatch', () => {
    let app: App;
    let socket: SocketIO.Socket;
    let socketServer: SocketIO.Server;
    let socketClient: SocketIO.Socket;
    let httpServer: http.Server;
    let endpointNetHandler: NetHandler;

    let netHandler: NetHandler;
    let subscriptionDispatch: SubscriptionDispatch;

    beforeEach((done) => {
        app = new App({...(App.DEFAULT_CONFIG), port: TestPortNumber()});

        httpServer = http.createServer();
        socketServer = sio(httpServer);
        socketClient = null;
        httpServer.listen(3000);

        socketServer.on('connection', (sc) => {
            socketClient = sc;
            endpointNetHandler = new NetHandler(socketClient);

            // Start the app
            app.start().then(() => done());
        });

        socket = sioc('http://localhost:3000') as any;
        (socket as {[key: string]: any})['client'] = {conn: {remoteAddress: 'TEST'}};

        // Create a new NetHandler for the SubscriptionDispatch
        netHandler = new NetHandler(socket);
    });

    afterEach((done) => {
        socket.disconnect();
        async.series([
            (callback: Function) => httpServer.close(() => callback()),
            (callback: Function) => app.stop().then(() => callback())
        ], done);
    });

    describe('constructor', () => {
        it('can construct without error', () => subscriptionDispatch = new SubscriptionDispatch(app, {netHandler: netHandler, userObj: null, authenticated: false} as any));
    });

    describe('#bind', () => {
        beforeEach(() => subscriptionDispatch = new SubscriptionDispatch(app, {netHandler: netHandler, userObj: null, authenticated: false} as any));

        it('can run without error', () => subscriptionDispatch.bind());

        it('can call addSubscription on a AddSubscriptionMessage with the subscription', (done) => {
            subscriptionDispatch = new SubscriptionDispatch(app, {netHandler: netHandler, userObj: null, authenticated: false} as any);

            const sub: ISubscription = {
                objectIds: ['1_TEST', '2_TEST', '3_TEST'],
                depth: 3,
                uid: shortid.generate(),
                limits: [],
                grabOwners: false
            };

            subscriptionDispatch.addSubscription = (subscription: ISubscription): Promise<void> => {
                expect(subscription).to.eql(sub);
                done();
                return new Promise<void>(() => {
                });
            };

            // Create the add sub message
            const addSubMsg = new AddSubscriptionMessage(endpointNetHandler);
            addSubMsg.subscription = sub;

            // Bind the subscription dispatch
            subscriptionDispatch.bind();

            // Send the message to the subscription dispatch
            endpointNetHandler.send(addSubMsg);
        });

        it('can call rmSubscription on a RmSubscriptionMessage with the subscription ids', (done) => {
            subscriptionDispatch = new SubscriptionDispatch(app, {netHandler: netHandler, userObj: null, authenticated: false} as any);

            const subIds = ['a', 'b', 'c', 'd'];

            subscriptionDispatch.rmSubscription = (subscriptionIds: string[]) => {
                expect(subscriptionIds).to.eql(subIds);
                done();
            };

            // Create the add sub message
            const rmSubMsg = new RmSubscriptionMessage(endpointNetHandler);
            rmSubMsg.subscriptionIds = subIds;

            // Bind the subscription dispatch
            subscriptionDispatch.bind();

            // Send the message to the subscription dispatch
            endpointNetHandler.send(rmSubMsg).catch((err) => done(err));
        });

        it('can call objUpdate on an obj SystemBus event', (done) => {
            subscriptionDispatch = new SubscriptionDispatch(app, {netHandler: netHandler, userObj: null, authenticated: false} as any);

            const obj: IObj = {
                _id: shortid.generate(),
                parentIds: [],
                ownerId: '',
                perms: _.cloneDeep(DefaultObjPerms),
                ctime: 1,
                mtime: 1,
                xtime: 0,
                rev: 0
            };

            subscriptionDispatch.objUpdate = async (obj: IObj) => {
                expect(obj).to.eql(obj);
                done();
            };

            // Bind the subscription dispatch
            subscriptionDispatch.bind();

            // Broadcast the event on the system bus
            app.systemBus.broadcast('obj', obj);
        });

        it('can call objRemove on an obj-remove SystemBus event', (done) => {
            subscriptionDispatch = new SubscriptionDispatch(app, {netHandler: netHandler, userObj: null, authenticated: false} as any);

            const objId = shortid.generate();

            subscriptionDispatch.objRemove = (objId: string) => {
                expect(objId).to.eql(objId);
                done();
            };

            // Bind the subscription dispatch
            subscriptionDispatch.bind();

            // Broadcast the event on the system bus
            app.systemBus.broadcast('obj-remove', objId);
        });

        it('can set the client cache when an ObjCacheStateMessage is received', (done) => {
            subscriptionDispatch = new SubscriptionDispatch(app, {netHandler: netHandler, userObj: null, authenticated: false} as any);

            // Make an IObjCacheState
            const state: IObjCacheState = {'0_TEST1': 4, '0_TEST2': 3};

            // Create the ObjCacheStateMessage
            const objCacheStateMessage = new ObjCacheStateMessage(endpointNetHandler);
            objCacheStateMessage.objCacheState = state;

            // Bind the subscription dispatch
            subscriptionDispatch.bind();

            // Send the message to the subscription dispatch
            endpointNetHandler.send(objCacheStateMessage).catch((err) => done(err));

            setTimeout(() => {
                expect(subscriptionDispatch.clientCacheState).to.eql(state);
                done();
            }, 50);
        });

        it('can call #objLookupByName and send any Objs back as an ObjMessage', (done) => {
            let obj = new Obj(app);

            subscriptionDispatch = new SubscriptionDispatch(app, {netHandler: netHandler, userObj: null, authenticated: false} as any);

            subscriptionDispatch.objLookupByName = (name: string, type: ObjType): Promise<Obj> => {
                expect(name).to.equal('TEST');
                expect(type).to.equal(9);
                return new Promise<Obj>((resolve) => resolve(obj));
            };

            subscriptionDispatch.bind();

            let objLookupByNameMessage = new ObjLookupByNameMessage(endpointNetHandler);
            objLookupByNameMessage.objName = 'TEST';
            objLookupByNameMessage.objType = 9;
            endpointNetHandler.send(objLookupByNameMessage).then((reply: Message) => {
                expect(reply.type).to.equal(MessageType.Obj);
                expect(reply.fields[MessageField.Objs][0]._id).to.equal(obj._id);
                done();
            }).catch((err) => done(err));
        });

        it('can call #objLookupByName and send a failed StatusMessage if null is returned', (done) => {
            subscriptionDispatch = new SubscriptionDispatch(app, {netHandler: netHandler, userObj: null, authenticated: false} as any);

            subscriptionDispatch.objLookupByName = (name: string, type: ObjType): Promise<Obj> => {
                expect(name).to.equal('TEST');
                expect(type).to.equal(9);
                return new Promise<Obj>((resolve) => resolve(null));
            };

            subscriptionDispatch.bind();

            let objLookupByNameMessage = new ObjLookupByNameMessage(endpointNetHandler);
            objLookupByNameMessage.objName = 'TEST';
            objLookupByNameMessage.objType = 9;
            endpointNetHandler.send(objLookupByNameMessage).then((reply: Message) => {
                expect(reply.type).to.equal(MessageType.Status);
                expect(reply.fields[MessageField.Success]).to.be.false;
                done();
            }).catch((err) => done(err));
        });
    });

    describe('#addSubscription', () => {
        let dbMock: DbMock;

        beforeEach((done) => {
            subscriptionDispatch = new SubscriptionDispatch(app, {netHandler: netHandler, userObj: null, authenticated: false} as any);
            dbMock = new DbMock(app);
            dbMock.run().then(() => done());
        });

        it('can return a promise', () => {
            expect(subscriptionDispatch.addSubscription({
                objectIds: [],
                depth: 0,
                uid: '',
                limits: [],
                grabOwners: false
            })).to.be.an.instanceof(Promise);
        });

        it('can store ISubscriptions', (done) => {
            const sub: ISubscription = {
                objectIds: ['1_TEST1'],
                depth: 0,
                uid: shortid.generate(),
                limits: [],
                grabOwners: false
            };

            subscriptionDispatch.addSubscription(sub).then(() => {
                expect(subscriptionDispatch.subscriptions).to.not.be.empty;
                expect(subscriptionDispatch.subscriptions[sub.uid]).to.equal(sub);
                done();
            }).catch((err) => done(err));
        });

        it('can push objects that fall under a 0-deep subscription to the client', (done) => {
            const sub: ISubscription = {
                objectIds: ['1_TEST1', '1_TEST2'],
                depth: 0,
                uid: shortid.generate(),
                limits: [],
                grabOwners: false
            };

            subscriptionDispatch.addSubscription(sub).catch((err) => done(err));

            endpointNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                let objMsg: ObjMessage = (new ObjMessage(endpointNetHandler)).encapsulate(msg);

                expect(objMsg.objs).to.have.lengthOf(2);
                expect(objMsg.objs).to.contain(dbMock.fixture.filter((o) => o._id === '1_TEST1')[0]);
                expect(objMsg.objs).to.contain(dbMock.fixture.filter((o) => o._id === '1_TEST2')[0]);
                done();
            });
        });

        it('can push objects that fall under a 1-deep subscription to the client', (done) => {
            const sub: ISubscription = {
                objectIds: ['1_TEST1'],
                depth: 1,
                uid: shortid.generate(),
                limits: [],
                grabOwners: false
            };

            subscriptionDispatch.addSubscription(sub).catch((err) => done(err));

            endpointNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                let objMsg: ObjMessage = (new ObjMessage(endpointNetHandler)).encapsulate(msg);

                expect(objMsg.objs).to.have.lengthOf(2);
                expect(objMsg.objs).to.contain(dbMock.fixture.filter((o) => o._id === '1_TEST1')[0]);
                expect(objMsg.objs).to.contain(dbMock.fixture.filter((o) => o._id === '1_TEST2')[0]);
                done();
            });
        });

        it('can push owners that fall under a 1-deep subscription to the client when grabOwners is set', (done) => {
            const sub: ISubscription = {
                objectIds: ['1_TEST1'],
                depth: 1,
                uid: shortid.generate(),
                limits: [],
                grabOwners: true
            };

            subscriptionDispatch.addSubscription(sub).catch((err) => done(err));

            endpointNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                let objMsg: ObjMessage = (new ObjMessage(endpointNetHandler)).encapsulate(msg);

                expect(objMsg.objs).to.have.lengthOf(3);
                expect(objMsg.objs).to.contain(dbMock.fixture.filter((o) => o._id === '1_TEST1')[0]);
                expect(objMsg.objs).to.contain(dbMock.fixture.filter((o) => o._id === '1_TEST2')[0]);
                expect(objMsg.objs).to.contain(dbMock.fixture.filter((o) => o._id === '3_USER1')[0]);
                done();
            });
        });

        it('can push objects that fall under a 2-deep subscription to the client', (done) => {
            const sub: ISubscription = {
                objectIds: ['1_TEST1'],
                depth: 2,
                uid: shortid.generate(),
                limits: [],
                grabOwners: false
            };

            subscriptionDispatch.addSubscription(sub).catch((err) => done(err));

            endpointNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                let objMsg: ObjMessage = (new ObjMessage(endpointNetHandler)).encapsulate(msg);

                expect(objMsg.objs).to.have.lengthOf(4);
                expect(objMsg.objs).to.contain(dbMock.fixture.filter((o) => o._id === '1_TEST1')[0]);
                expect(objMsg.objs).to.contain(dbMock.fixture.filter((o) => o._id === '1_TEST2')[0]);
                expect(objMsg.objs).to.contain(dbMock.fixture.filter((o) => o._id === '1_TEST3')[0]);
                expect(objMsg.objs).to.contain(dbMock.fixture.filter((o) => o._id === '1_TEST4')[0]);
                done();
            });
        });

        it('can push objects that fall under a 2-deep subscription to the client obeying limits', (done) => {
            const sub: ISubscription = {
                objectIds: ['1_TEST1'],
                depth: 2,
                uid: shortid.generate(),
                limits: [null, 1],
                grabOwners: false
            };

            subscriptionDispatch.addSubscription(sub).catch((err) => done(err));

            endpointNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                let objMsg: ObjMessage = (new ObjMessage(endpointNetHandler)).encapsulate(msg);

                expect(objMsg.objs).to.have.lengthOf(3);
                expect(objMsg.objs).to.contain(dbMock.fixture.filter((o) => o._id === '1_TEST1')[0]);
                expect(objMsg.objs).to.contain(dbMock.fixture.filter((o) => o._id === '1_TEST2')[0]);
                expect(objMsg.objs).to.contain(dbMock.fixture.filter((o) => o._id === '1_TEST4')[0]);
                done();
            });
        });

        it('can send the cause subscription ID to the client', (done) => {
            const sub: ISubscription = {
                objectIds: ['1_TEST1', '1_TEST2'],
                depth: 0,
                uid: shortid.generate(),
                limits: [],
                grabOwners: false
            };

            subscriptionDispatch.addSubscription(sub).catch((err) => done(err));

            endpointNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                let objMsg: ObjMessage = (new ObjMessage(endpointNetHandler)).encapsulate(msg);

                expect(objMsg.subObjMap).to.eql({[sub.uid]: objMsg.objs.map((obj) => obj._id)});

                done();
            });
        });

        it('can build an object hierarchy cache for a 0-deep subscription', (done) => {
            const sub: ISubscription = {
                objectIds: ['1_TEST1', '1_TEST2'],
                depth: 0,
                uid: shortid.generate(),
                limits: [],
                grabOwners: false
            };

            subscriptionDispatch.addSubscription(sub).catch((err) => done(err));

            subscriptionDispatch.addSubscription(sub).then(() => {
                expect(subscriptionDispatch.objCache).to.have.property(sub.uid);
                const cache = subscriptionDispatch.objCache[sub.uid];

                // Expect it to have created an entry for 1TEST2
                expect(cache).to.have.property('1_TEST1');
                expect(cache['1_TEST1']).to.be.empty;
                // Expect it to have created an entry for child 1TEST2
                expect(cache).to.have.property('1_TEST2');
                // Expect it to have only 1TEST1 as a cached parent
                expect(cache['1_TEST2']).to.eql(['1_TEST1']);

                done();
            }).catch((err) => done(err));
        });

        it('can clean out-of-subscription references from the object cache', (done) => {
            const sub: ISubscription = {
                objectIds: ['1_TEST2'],
                depth: 0,
                uid: shortid.generate(),
                limits: [],
                grabOwners: false
            };

            subscriptionDispatch.addSubscription(sub).catch((err) => done(err));

            subscriptionDispatch.addSubscription(sub).then(() => {
                expect(subscriptionDispatch.objCache).to.have.property(sub.uid);
                const cache = subscriptionDispatch.objCache[sub.uid];

                // Expect it to have created an entry for 1TEST2
                expect(cache).to.have.property('1_TEST2');
                // Expect it to have no cached parents as they fall out of the subscription
                expect(cache['1_TEST2']).to.be.empty;

                done();
            }).catch((err) => done(err));
        });

        it('can build an object hierarchy cache for a 1-deep subscription', (done) => {
            const sub: ISubscription = {
                objectIds: ['1_TEST1'],
                depth: 1,
                uid: shortid.generate(),
                limits: [],
                grabOwners: false
            };

            subscriptionDispatch.addSubscription(sub).catch((err) => done(err));

            subscriptionDispatch.addSubscription(sub).then(() => {
                expect(subscriptionDispatch.objCache).to.have.property(sub.uid);
                const cache = subscriptionDispatch.objCache[sub.uid];

                // Expect it to have created an entry for 1TEST1
                expect(cache).to.have.property('1_TEST1');
                // Expect it to have no cached parents as they fall out of the subscription
                expect(cache['1_TEST1']).to.be.empty;
                // Expect it to have created an entry for child 1TEST2
                expect(cache).to.have.property('1_TEST2');
                // Expect it to have only 1TEST1 as a cached parent
                expect(cache['1_TEST2']).to.eql(['1_TEST1']);

                done();
            }).catch((err) => done(err));
        });

        it('can build an object hierarchy cache for a 1-deep subscription with owners grabbed', (done) => {
            const sub: ISubscription = {
                objectIds: ['1_TEST1'],
                depth: 1,
                uid: shortid.generate(),
                limits: [],
                grabOwners: true
            };

            subscriptionDispatch.addSubscription(sub).catch((err) => done(err));

            subscriptionDispatch.addSubscription(sub).then(() => {
                expect(subscriptionDispatch.objCache).to.have.property(sub.uid);
                const cache = subscriptionDispatch.objCache[sub.uid];

                // Expect it to have created an entry for 1TEST1
                expect(cache).to.have.property('1_TEST1');
                // Expect it to have no cached parents as they fall out of the subscription
                expect(cache['1_TEST1']).to.be.empty;
                // Expect it to have created an entry for child 1TEST2
                expect(cache).to.have.property('1_TEST2');
                // Expect it to have only 1TEST1 as a cached parent
                expect(cache['1_TEST2']).to.eql(['1_TEST1']);
                // Expect it to have an entry for owner 3USER1
                expect(cache).to.have.property('3_USER1');
                // Expect it to have only 1TEST1 as a cached parent
                expect(cache['3_USER1']).to.eql(['1_TEST1']);

                done();
            }).catch((err) => done(err));
        });

        it('can build an object hierarchy cache for a 2-deep subscription', (done) => {
            const sub: ISubscription = {
                objectIds: ['1_TEST1'],
                depth: 2,
                uid: shortid.generate(),
                limits: [],
                grabOwners: false
            };

            subscriptionDispatch.addSubscription(sub).catch((err) => done(err));

            subscriptionDispatch.addSubscription(sub).then(() => {
                expect(subscriptionDispatch.objCache).to.have.property(sub.uid);
                const cache = subscriptionDispatch.objCache[sub.uid];

                // Expect it to have created an entry for 1TEST1
                expect(cache).to.have.property('1_TEST1');
                // Expect it to have no cached parents as they fall out of the subscription
                expect(cache['1_TEST1']).to.be.empty;
                // Expect it to have created an entry for child 1TEST2
                expect(cache).to.have.property('1_TEST2');
                // Expect it to have only 1TEST1 as a cached parent
                expect(cache['1_TEST2']).to.eql(['1_TEST1']);
                // Expect it to have created an entry for child 1TEST3
                expect(cache).to.have.property('1_TEST3');
                // Expect it to have only 1TEST1 as a cached parent
                expect(cache['1_TEST3']).to.eql(['1_TEST2']);
                // Expect it to have created an entry for child 1TEST4
                expect(cache).to.have.property('1_TEST4');
                // Expect it to have only 1TEST1 as a cached parent
                expect(cache['1_TEST4']).to.eql(['1_TEST2']);

                done();
            }).catch((err) => done(err));
        });
    });

    describe('#rmSubscription', () => {
        let dbMock: DbMock;
        let sub: ISubscription;

        beforeEach((done) => {
            subscriptionDispatch = new SubscriptionDispatch(app, {netHandler: netHandler, userObj: null, authenticated: false} as any);
            dbMock = new DbMock(app);
            sub = {
                objectIds: ['1_TEST1', '1_TEST2'],
                depth: 0,
                uid: shortid.generate(),
                limits: [],
                grabOwners: false
            };
            dbMock.run().then(() => subscriptionDispatch.addSubscription(sub)).then(() => done());
        });

        it('can return a promise', () => {
            expect(subscriptionDispatch.addSubscription({
                objectIds: [],
                depth: 0,
                uid: '',
                limits: [],
                grabOwners: false
            })).to.be.an.instanceof(Promise);
        });

        it('can delete the subscriptions referenced by the provided ids', () => {
            subscriptionDispatch.rmSubscription([sub.uid]);
            expect(subscriptionDispatch.subscriptions).to.be.empty;
        });

        it('can delete the object hierarchy caches referenced by the provided ids', () => {
            subscriptionDispatch.rmSubscription([sub.uid]);
            expect(subscriptionDispatch.objCache).to.be.empty;
        });
    });

    describe('#objUpdate', () => {
        let dbMock: DbMock;
        let sub: ISubscription;

        beforeEach((done) => {
            subscriptionDispatch = new SubscriptionDispatch(app, {netHandler: netHandler, userObj: null, authenticated: false} as any);
            dbMock = new DbMock(app);

            subscriptionDispatch.bind();
            dbMock.run().then(() => done()).catch((err) => done(err));
        });

        describe('zero/any depth', () => {
            beforeEach((done) => {
                sub = {
                    objectIds: [dbMock.fixture[1]._id],
                    depth: 0,
                    uid: shortid.generate(),
                    limits: [],
                    grabOwners: false
                };

                let objMsgHandler = () => {
                    endpointNetHandler.removeListener('msg-' + MessageType.Obj, objMsgHandler);
                    done();
                };
                endpointNetHandler.onMessage(MessageType.Obj, objMsgHandler); // Done when first message received

                subscriptionDispatch.addSubscription(sub).then(() => {
                });
            });

            it('can push an Obj update to the client', (done) => {
                let update: IBoard = _.cloneDeep(<IBoard>dbMock.fixture[1]);
                update.name = 'SUBDISPATCHTEST';
                update.rev++;

                endpointNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                    let objMsg: ObjMessage = (new ObjMessage(endpointNetHandler)).encapsulate(msg);
                    expect(objMsg.objs).to.not.be.empty;
                    expect(objMsg.objs[0]).to.eql(update);
                    done();
                });

                app.systemBus.broadcast('obj', update);
            });

            it('can send the cause subscription ID in an SubObjMap to the client', (done) => {
                let update: IBoard = _.cloneDeep(<IBoard>dbMock.fixture[1]);
                update.name = 'SUBDISPATCHTEST';
                update.rev++;

                endpointNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                    let objMsg: ObjMessage = (new ObjMessage(endpointNetHandler)).encapsulate(msg);
                    expect(objMsg.subObjMap).to.eql({[sub.uid]: [objMsg.objs[0]._id]});
                    done();
                });

                app.systemBus.broadcast('obj', update);
            });

            it('can update the client cache state when an Obj is sent to the client', (done) => {
                let update: IBoard = _.cloneDeep(<IBoard>dbMock.fixture[1]);
                update.name = 'SUBDISPATCHTEST';
                update.rev++;

                endpointNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                    expect(subscriptionDispatch.clientCacheState[update._id]).to.equal(update.rev);
                    done();
                });

                app.systemBus.broadcast('obj', update);
            });

            it('does not send an Obj on update if the revision in the ObjCacheState is above the Obj being updated', (done) => {
                let update: IBoard = _.cloneDeep(<IBoard>dbMock.fixture[1]);
                update.name = 'SUBDISPATCHTEST';
                subscriptionDispatch.clientCacheState[update._id] = update.rev + 4;

                endpointNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                    clearTimeout(timeout);
                    if(_.isEmpty(new ObjMessage(netHandler).encapsulate(msg).objs)) return done();
                    done(new Error('no Obj should\'ve been sent'));
                });

                let timeout = setTimeout(() => {
                    done();
                }, 50);

                app.systemBus.broadcast('obj', update);
            });

            it('does not send an Obj on update if the revision in the ObjCacheState is equal to the Obj being updated', (done) => {
                let update: IBoard = _.cloneDeep(<IBoard>dbMock.fixture[1]);
                update.name = 'SUBDISPATCHTEST';
                subscriptionDispatch.clientCacheState[update._id] = update.rev;

                endpointNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                    clearTimeout(timeout);
                    if(_.isEmpty(new ObjMessage(netHandler).encapsulate(msg).objs)) return done();
                    done(new Error('no Obj should\'ve been sent'));
                });

                let timeout = setTimeout(() => {
                    done();
                }, 50);

                app.systemBus.broadcast('obj', update);
            });

            it('does not send an Obj if the permissions specify it must not be viewed by all', (done) => {
                let update: IBoard = _.cloneDeep(<IBoard>dbMock.fixture[1]);
                update.name = 'SUBDISPATCHTEST';
                update.rev++;
                update.perms.all.view = false;

                endpointNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                    clearTimeout(timeout);
                    if(_.isEmpty(new ObjMessage(netHandler).encapsulate(msg).objs)) return done();
                    done(new Error('no Obj should\'ve been sent'));
                });

                let timeout = setTimeout(() => {
                    done();
                }, 50);

                app.systemBus.broadcast('obj', update);
            });

            it('does not modify the Obj cache on a non-hierarchy-modifying Obj update', (done) => {
                let update: IBoard = _.cloneDeep(<IBoard>dbMock.fixture[1]);
                update.name = 'SUBDISPATCHTEST';
                update.rev++;

                let cache = _.cloneDeep(subscriptionDispatch.objCache);

                endpointNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                    let objMsg: ObjMessage = (new ObjMessage(endpointNetHandler)).encapsulate(msg);
                    expect(subscriptionDispatch.objCache).to.eql(cache);

                    done();
                });

                app.systemBus.broadcast('obj', update);
            });

            it('can correctly update the Obj cache and clean unresolvable references on a hierarchy-modifying Obj update', (done) => {
                let update: IBoard = _.cloneDeep(<IBoard>dbMock.fixture[1]);
                update.parentIds = [dbMock.fixture[0]._id];
                update.rev++;
                let cache = _.cloneDeep(subscriptionDispatch.objCache);
                cache[sub.uid][dbMock.fixture[1]._id] = [];

                endpointNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                    let objMsg: ObjMessage = (new ObjMessage(endpointNetHandler)).encapsulate(msg);
                    expect(subscriptionDispatch.objCache).to.eql(cache);

                    done();
                });

                app.systemBus.broadcast('obj', update);
            });

            it('can ignore an Obj that does not fall under any subscription', (done) => {
                let update: IObj = {
                    _id: '0_' + shortid.generate(),
                    parentIds: ['1_Blah', '1_blah', '1_blah'],
                    ownerId: null,
                    perms: _.cloneDeep(DefaultObjPerms),
                    ctime: 1,
                    mtime: 1,
                    xtime: 0,
                    rev: 1
                };

                let cache = _.cloneDeep(subscriptionDispatch.objCache[sub.uid]);

                endpointNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                    done(new Error('an Obj was pushed when it should not have'));
                });

                app.systemBus.broadcast('obj', update);

                setTimeout(() => {
                    expect(subscriptionDispatch.objCache[sub.uid]).to.eql(cache);
                    done();
                }, 200);
            });
        });

        describe('single depth', () => {
            beforeEach((done) => {
                sub = {
                    objectIds: [dbMock.fixture[1]._id],
                    depth: 1,
                    uid: shortid.generate(),
                    limits: [],
                    grabOwners: false
                };

                let objMsgHandler = () => {
                    endpointNetHandler.removeListener('msg-' + MessageType.Obj, objMsgHandler);
                    done();
                };
                endpointNetHandler.onMessage(MessageType.Obj, objMsgHandler); // Done when first message received

                subscriptionDispatch.addSubscription(sub).then(() => {
                });
            });

            it('can leave resolvable parent references on Obj update', (done) => {
                let update: IBoard = _.cloneDeep(<IBoard>dbMock.fixture[2]);
                let cache = _.cloneDeep(subscriptionDispatch.objCache);
                update.rev++;

                endpointNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                    let objMsg: ObjMessage = (new ObjMessage(endpointNetHandler)).encapsulate(msg);
                    expect(subscriptionDispatch.objCache).to.eql(cache);

                    done();
                });

                app.systemBus.broadcast('obj', update);
            });

            it('can push a new Obj that falls under the subscription', (done) => {
                let update: IObj = {
                    _id: '0_' + shortid.generate(),
                    parentIds: [dbMock.fixture[1]._id],
                    ownerId: null,
                    perms: _.cloneDeep(DefaultObjPerms),
                    ctime: 1,
                    mtime: 1,
                    xtime: 0,
                    rev: 0
                };

                endpointNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                    let objMsg: ObjMessage = (new ObjMessage(endpointNetHandler)).encapsulate(msg);
                    expect(objMsg.objs).to.have.lengthOf(1);
                    expect(objMsg.objs[0]).to.eql(update);

                    done();
                });

                app.systemBus.broadcast('obj', update);
            });

            it('can send the cause subscription ID to the client for a new Obj', (done) => {
                let update: IObj = {
                    _id: '0_' + shortid.generate(),
                    parentIds: [dbMock.fixture[1]._id],
                    ownerId: null,
                    perms: _.cloneDeep(DefaultObjPerms),
                    ctime: 1,
                    mtime: 1,
                    xtime: 0,
                    rev: 0
                };

                endpointNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                    let objMsg: ObjMessage = (new ObjMessage(endpointNetHandler)).encapsulate(msg);
                    expect(objMsg.subObjMap).to.eql({[sub.uid]: objMsg.objs.map((obj) => obj._id)});

                    done();
                });

                app.systemBus.broadcast('obj', update);
            });

            it('does not send a new Obj if the client already has it', (done) => {
                let update: IObj = {
                    _id: '0_' + shortid.generate(),
                    parentIds: [dbMock.fixture[1]._id],
                    ownerId: null,
                    perms: _.cloneDeep(DefaultObjPerms),
                    ctime: 1,
                    mtime: 1,
                    xtime: 0,
                    rev: 0
                };
                subscriptionDispatch.clientCacheState[update._id] = update.rev + 4;

                endpointNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                    clearTimeout(timeout);
                    if(_.isEmpty(new ObjMessage(netHandler).encapsulate(msg).objs)) return done();
                    done(new Error('no Obj should\'ve been sent'));
                });

                let timeout = setTimeout(() => {
                    done();
                }, 50);

                app.systemBus.broadcast('obj', update);
            });

            it('can add a new Obj that falls under the subscription to the obj hierarchy cache', (done) => {
                let update: IObj = {
                    _id: '0_' + shortid.generate(),
                    parentIds: [dbMock.fixture[1]._id],
                    ownerId: null,
                    perms: _.cloneDeep(DefaultObjPerms),
                    ctime: 1,
                    mtime: 1,
                    xtime: 0,
                    rev: 0
                };

                endpointNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                    let objMsg: ObjMessage = (new ObjMessage(endpointNetHandler)).encapsulate(msg);
                    expect(subscriptionDispatch.objCache[sub.uid][update._id]).to.eql([dbMock.fixture[1]._id]);

                    done();
                });

                app.systemBus.broadcast('obj', update);
            });

            it('can update a new Obj that was added by falling under the subscription', (done) => {
                let update: IObj = {
                    _id: '0_' + shortid.generate(),
                    parentIds: [dbMock.fixture[1]._id],
                    ownerId: null,
                    perms: _.cloneDeep(DefaultObjPerms),
                    ctime: 1,
                    mtime: 1,
                    xtime: 0,
                    rev: 1
                };
                let pass = 0;

                endpointNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                    let objMsg: ObjMessage = (new ObjMessage(endpointNetHandler)).encapsulate(msg);

                    if (pass === 0) {
                        pass++;

                        expect(subscriptionDispatch.objCache[sub.uid][update._id]).to.eql([dbMock.fixture[1]._id]);

                        update.ctime = 1337;
                        update.rev++;
                        app.systemBus.broadcast('obj', update);
                    } else {
                        expect(objMsg.objs).to.have.lengthOf(1);
                        expect(objMsg.objs[0].ctime).to.eql(1337);
                        done();
                    }
                });

                app.systemBus.broadcast('obj', update);
            });

            it('can ignore a new Obj that falls outside of the subscription depth', (done) => {
                let update: IObj = {
                    _id: '0_' + shortid.generate(),
                    parentIds: [dbMock.fixture[1]._id],
                    ownerId: null,
                    perms: _.cloneDeep(DefaultObjPerms),
                    ctime: 1,
                    mtime: 1,
                    xtime: 0,
                    rev: 0
                };
                let pass = 0;

                endpointNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                    let objMsg: ObjMessage = (new ObjMessage(endpointNetHandler)).encapsulate(msg);

                    if (pass === 0) {
                        pass++;

                        expect(subscriptionDispatch.objCache[sub.uid][update._id]).to.eql([dbMock.fixture[1]._id]);

                        update = {
                            _id: '0_' + shortid.generate(),
                            parentIds: [update._id],
                            ownerId: null,
                            perms: _.cloneDeep(DefaultObjPerms),
                            ctime: 1,
                            mtime: 1,
                            xtime: 0,
                            rev: 0
                        };

                        app.systemBus.broadcast('obj', update);

                        setTimeout(() => {
                            expect(subscriptionDispatch.objCache[sub.uid][update._id]).to.equal(undefined);
                            done();
                        }, 200);
                    } else {
                        done(new Error('a second Obj update should not have been sent'));
                    }
                });

                app.systemBus.broadcast('obj', update);
            });

            it('can correctly tag a new Obj when it falls under multiple subscriptions', (done) => {
                let secondSub: ISubscription;
                async.series(
                    [
                        (callback) => {
                            secondSub = {
                                objectIds: [dbMock.fixture[0]._id],
                                depth: 2,
                                uid: shortid.generate(),
                                limits: [],
                                grabOwners: false
                            };

                            let objMsgHandler = () => {
                                endpointNetHandler.removeListener('msg-' + MessageType.Obj, objMsgHandler);
                                callback();
                            };
                            endpointNetHandler.onMessage(MessageType.Obj, objMsgHandler); // Done when first message received

                            subscriptionDispatch.addSubscription(secondSub).catch((err) => callback(err));
                        },
                        (callback) => {
                            let update: IObj = {
                                _id: '0_' + shortid.generate(),
                                parentIds: [dbMock.fixture[1]._id],
                                ownerId: null,
                                perms: _.cloneDeep(DefaultObjPerms),
                                ctime: 1,
                                mtime: 1,
                                xtime: 0,
                                rev: 0
                            };

                            endpointNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                                let objMsg: ObjMessage = (new ObjMessage(endpointNetHandler)).encapsulate(msg);
                                expect(objMsg.objs).to.have.lengthOf(1);
                                expect(objMsg.objs[0]).to.eql(update);
                                expect(_.keys(objMsg.subObjMap)).to.include(sub.uid);
                                expect(_.keys(objMsg.subObjMap)).to.include(secondSub.uid);

                                callback();
                            });

                            app.systemBus.broadcast('obj', update);
                        }
                    ],
                    done
                );
            });
        });

        describe('two-depth', () => {
            beforeEach((done) => {
                sub = {
                    objectIds: [dbMock.fixture[0]._id],
                    depth: 2,
                    uid: shortid.generate(),
                    limits: [],
                    grabOwners: false
                };

                let objMsgHandler = () => {
                    endpointNetHandler.removeListener('msg-' + MessageType.Obj, objMsgHandler);
                    done();
                };
                endpointNetHandler.onMessage(MessageType.Obj, objMsgHandler); // Done when first message received

                subscriptionDispatch.addSubscription(sub).then(() => {
                });
            });

            it('can push a new Obj that falls under the subscription', (done) => {
                let update: IObj = {
                    _id: '0_' + shortid.generate(),
                    parentIds: [dbMock.fixture[1]._id],
                    ownerId: null,
                    perms: _.cloneDeep(DefaultObjPerms),
                    ctime: 1,
                    mtime: 1,
                    xtime: 0,
                    rev: 0
                };

                endpointNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                    let objMsg: ObjMessage = (new ObjMessage(endpointNetHandler)).encapsulate(msg);
                    expect(objMsg.objs).to.have.lengthOf(1);
                    expect(objMsg.objs[0]).to.eql(update);

                    done();
                });

                app.systemBus.broadcast('obj', update);
            });

            it('can add a new Obj that falls under the subscription to the obj hierarchy cache', (done) => {
                let update: IObj = {
                    _id: '0_' + shortid.generate(),
                    parentIds: [dbMock.fixture[1]._id],
                    ownerId: null,
                    perms: _.cloneDeep(DefaultObjPerms),
                    ctime: 1,
                    mtime: 1,
                    xtime: 0,
                    rev: 0
                };

                endpointNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                    let objMsg: ObjMessage = (new ObjMessage(endpointNetHandler)).encapsulate(msg);
                    expect(subscriptionDispatch.objCache[sub.uid][update._id]).to.eql([dbMock.fixture[1]._id]);

                    done();
                });

                app.systemBus.broadcast('obj', update);
            });

            it('can ignore a new Obj that falls outside of the subscription depth', (done) => {
                let update: IObj = {
                    _id: '0_' + shortid.generate(),
                    parentIds: [dbMock.fixture[1]._id],
                    ownerId: null,
                    perms: _.cloneDeep(DefaultObjPerms),
                    ctime: 1,
                    mtime: 1,
                    xtime: 0,
                    rev: 0
                };
                let pass = 0;

                endpointNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                    let objMsg: ObjMessage = (new ObjMessage(endpointNetHandler)).encapsulate(msg);

                    if (pass === 0) {
                        pass++;

                        expect(subscriptionDispatch.objCache[sub.uid][update._id]).to.eql([dbMock.fixture[1]._id]);

                        update = {
                            _id: '0_' + shortid.generate(),
                            parentIds: [update._id],
                            ownerId: null,
                            perms: _.cloneDeep(DefaultObjPerms),
                            ctime: 1,
                            mtime: 1,
                            xtime: 0,
                            rev: 0
                        };

                        app.systemBus.broadcast('obj', update);

                        setTimeout(() => {
                            expect(subscriptionDispatch.objCache[sub.uid][update._id]).to.equal(undefined);
                            done();
                        }, 200);
                    } else {
                        done(new Error('a second Obj update should not have been sent'));
                    }
                });

                app.systemBus.broadcast('obj', update);
            });
        });

        describe('grabOwners', () => {
            beforeEach((done) => {
                sub = {
                    objectIds: [dbMock.fixture[0]._id],
                    depth: 2,
                    uid: shortid.generate(),
                    limits: [],
                    grabOwners: true
                };

                let objMsgHandler = () => {
                    endpointNetHandler.removeListener('msg-' + MessageType.Obj, objMsgHandler);
                    done();
                };
                endpointNetHandler.onMessage(MessageType.Obj, objMsgHandler); // Done when first message received

                subscriptionDispatch.addSubscription(sub).then(() => {
                });
            });

            it('can push the owner of a new Obj that falls under the subscription when the owner remains in-depth', (done) => {
                let update: IObj = {
                    _id: '0_' + shortid.generate(),
                    parentIds: [dbMock.fixture[0]._id],
                    ownerId: `${ObjType.User}_USER2`,
                    perms: _.cloneDeep(DefaultObjPerms),
                    ctime: 1,
                    mtime: 1,
                    xtime: 0,
                    rev: 0
                };

                endpointNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                    let objMsg: ObjMessage = (new ObjMessage(endpointNetHandler)).encapsulate(msg);
                    expect(objMsg.objs).to.have.lengthOf(2);
                    expect(objMsg.objs.filter((iobj) => iobj._id === update._id)[0]).to.eql(update);
                    expect(objMsg.objs.filter((iobj) => iobj._id === update.ownerId)[0]).to.eql(dbMock.fixture.filter((iobj) => iobj._id === update.ownerId)[0]);

                    done();
                });

                app.systemBus.broadcast('obj', update);
            });

            it('can add the owner of a new Obj that falls under the subscription to the obj hierarchy cache when the owner remains in-depth', (done) => {
                let update: IObj = {
                    _id: '0_' + shortid.generate(),
                    parentIds: [dbMock.fixture[0]._id],
                    ownerId: `${ObjType.User}_USER2`,
                    perms: _.cloneDeep(DefaultObjPerms),
                    ctime: 1,
                    mtime: 1,
                    xtime: 0,
                    rev: 0
                };

                endpointNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                    expect(subscriptionDispatch.objCache[sub.uid][`${ObjType.User}_USER2`]).to.eql([update._id]);

                    done();
                });

                app.systemBus.broadcast('obj', update);
            });

            it('won\'t push the owner of a new Obj that falls under the subscription when the owner is not in-depth', (done) => {
                let update: IObj = {
                    _id: '0_' + shortid.generate(),
                    parentIds: [dbMock.fixture[1]._id],
                    ownerId: `${ObjType.User}_USER2`,
                    perms: _.cloneDeep(DefaultObjPerms),
                    ctime: 1,
                    mtime: 1,
                    xtime: 0,
                    rev: 0
                };

                endpointNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                    let objMsg: ObjMessage = (new ObjMessage(endpointNetHandler)).encapsulate(msg);
                    expect(objMsg.objs).to.have.lengthOf(1);
                    expect(objMsg.objs.filter((iobj) => iobj._id === update._id)[0]).to.eql(update);

                    done();
                });

                app.systemBus.broadcast('obj', update);
            });
        });
    });

    describe('#objRemove', () => {
        let dbMock: DbMock;
        let sub: ISubscription;

        beforeEach((done) => {
            subscriptionDispatch = new SubscriptionDispatch(app, {netHandler: netHandler, userObj: null, authenticated: false} as any);
            dbMock = new DbMock(app);

            sub = {
                objectIds: [dbMock.fixture[0]._id],
                depth: 2,
                uid: shortid.generate(),
                limits: [],
                grabOwners: false
            };

            let objMsgHandler = () => {
                endpointNetHandler.removeListener('msg-' + MessageType.Obj, objMsgHandler);
                done();
            };
            endpointNetHandler.onMessage(MessageType.Obj, objMsgHandler); // Done when first message received

            subscriptionDispatch.bind();
            dbMock.run().then(() => subscriptionDispatch.addSubscription(sub)).catch((err) => done(err));
        });

        it('can send an RmObj message containing the Obj IDs removed', (done) => {
            endpointNetHandler.onMessage(MessageType.RmObj, (msg: Message) => {
                let rmObjMsg: RmObjMessage = (new RmObjMessage(endpointNetHandler)).encapsulate(msg);

                expect(rmObjMsg.objIds).to.eql([dbMock.fixture[2]._id]);

                done();
            });

            subscriptionDispatch.objRemove(dbMock.fixture[2]._id);
        });

        it('can remove a tail Obj from the cache', (done) => {
            expect(subscriptionDispatch.objCache[sub.uid]).to.have.property(dbMock.fixture[2]._id);

            endpointNetHandler.onMessage(MessageType.RmObj, (msg: Message) => {
                let rmObjMsg: RmObjMessage = (new RmObjMessage(endpointNetHandler)).encapsulate(msg);

                expect(subscriptionDispatch.objCache[sub.uid]).to.not.have.property(dbMock.fixture[2]._id);

                done();
            });

            subscriptionDispatch.objRemove(dbMock.fixture[2]._id);
        });

        it('can remove an Obj\'s children from the cache', (done) => {
            expect(subscriptionDispatch.objCache[sub.uid]).to.have.property(dbMock.fixture[1]._id);
            expect(subscriptionDispatch.objCache[sub.uid]).to.have.property(dbMock.fixture[2]._id);

            endpointNetHandler.onMessage(MessageType.RmObj, (msg: Message) => {
                let rmObjMsg: RmObjMessage = (new RmObjMessage(endpointNetHandler)).encapsulate(msg);

                expect(subscriptionDispatch.objCache[sub.uid]).to.not.have.property(dbMock.fixture[1]._id);
                expect(subscriptionDispatch.objCache[sub.uid]).to.not.have.property(dbMock.fixture[2]._id);

                done();
            });

            subscriptionDispatch.objRemove(dbMock.fixture[1]._id);
        });
    });

    describe('#objLookupByName', () => {
        let dbMock: DbMock;

        beforeEach((done) => {
            subscriptionDispatch = new SubscriptionDispatch(app, {netHandler: netHandler, userObj: null, authenticated: false} as any);
            dbMock = new DbMock(app);
            dbMock.run().then(() => done()).catch((err) => done(err));
        });

        it('can find an Obj of a specified type by name', (done) => {
            let target = <IBoard>dbMock.fixture[0];
            subscriptionDispatch.objLookupByName(target.name, parseInt(target._id[0])).then((obj: Obj) => {
                expect(obj).to.be.an.instanceof(Obj);
                expect(obj.getProps()).to.eql(target);
                done();
            }).catch((err) => done(err));
        });

        it('can return null if the Obj is found in another type', (done) => {
            let target = <IBoard>dbMock.fixture[0];
            subscriptionDispatch.objLookupByName(target.name, 9).then((obj: Obj) => {
                expect(obj).to.be.null;
                done();
            }).catch((err) => done(err));
        });

        it('can return null if the Obj doesn\'t exist', (done) => {
            subscriptionDispatch.objLookupByName('NO_EXIST', 1).then((obj: Obj) => {
                expect(obj).to.be.null;
                done();
            }).catch((err) => done(err));
        });
    });
});