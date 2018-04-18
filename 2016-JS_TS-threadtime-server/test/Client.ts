/// <reference path="../node_modules/@types/mocha/index.d.ts" />

import { expect } from 'chai';
import * as _ from 'lodash';
import * as crypto from 'crypto';

import * as http from 'http';
import * as sio from 'socket.io';
import * as sioc from 'socket.io-client';
import * as bcrypt from 'bcrypt';
import * as async from 'async';

import { EventEmitter } from 'events';

import {
    MessageType, Message, AuthMessage, HandshakeMessage, PermanentDisconnectMessage, DisconnectMachineReason,
    NetHandler, StatusMessage, IObj, ObjMessage, IUser, IBoard, ObjType, DefaultObjPerms, Obj as ObjCommon,
    UnAuthMessage, HandshakeResponseMessage, ObjCacheStateMessage, RmObjMessage, MessageField
} from '@threadtime/threadtime-common';
import { App, Client, UserObj } from '../src';
import { DbMock } from "./DbMock";
import {TestPortNumber} from "./TestPortNumber";
import {Obj} from "../src/Objs/Obj";
import {PostObj} from "../src/Objs/PostObj";

describe('Client', () => {
    let app: App;
    let client: Client;
    let socket: SocketIO.Socket;
    let socketServer: SocketIO.Server;
    let socketClient: SocketIO.Socket;
    let httpServer: http.Server;

    beforeEach(async () => {
        app = new App({...(App.DEFAULT_CONFIG), port: TestPortNumber()});

        httpServer = http.createServer();
        socketServer = sio(httpServer);
        socketClient = null;
        httpServer.listen(3000);

        socket = sioc('http://localhost:3000') as any;
        (socket as {[key: string]: any})['client'] = {conn: {remoteAddress: 'TEST'}};
        client = new Client(app, socket);

        // Start the app
        await Promise.all([
            app.start(),
            new Promise<void>((resolve) =>
                socketServer.on('connection', (sc) => {
                    socketClient = sc;
                    resolve()
                })
            )
        ]);
    });

    afterEach((done) => {
        socket.disconnect();
        async.series([
            (callback: Function) => httpServer.close(callback),
            (callback: Function) => app.stop().then(() => callback())
        ], done);
    });

    describe('#start', () => {
        it('can add a disconnect handler', () => {
            client.start();
            expect(socket.listeners('disconnect').length).to.be.above(0);
        });

        it('can call a message receive handler for Handshake messages in NetHandler', () => {
            class NetHandlerMock extends NetHandler {
                onMessage(type: MessageType, handler: Function) {
                    expect(type).to.equal(MessageType.Handshake);
                    expect(handler).to.be.a('function');
                }
            }

            client.netHandler = new NetHandlerMock(socket as SocketIO.Socket);
            client.start();
        });

        it('can bind a SubscriptionDispatch', (done) => {
            client.subscriptionDispatch.bind = () => done();
            client.start()
        });
    });

    describe('#stop', () => {
        it('can disconnect the socket when #stop is called', (done) => {
            client.start();
            client.stop().then(() => {
                expect(socket.disconnected).to.equal(true);
                done();
            });
        });
    });

    describe('handshakes', () => {
        beforeEach((done) => setTimeout(done, 10)); // Put this on a delay so socketClient can establish

        it('can respond to a HandshakeMessage with a HandshakeResponseMessage', (done) => {
            let reqNetHandler = new NetHandler(socketClient);
            let reqHandshake = new HandshakeMessage(reqNetHandler);
            reqHandshake.version = App.VERSION;

            client.start();
            reqNetHandler.send(reqHandshake).then((reply: Message) => {
                let respHandshake = new HandshakeResponseMessage(reqNetHandler).encapsulate(reply);
                expect(respHandshake.type).to.equal(MessageType.HandshakeResponse);
                expect(respHandshake.version).to.equal(App.VERSION);
                expect(respHandshake.serverName).to.equal(app.serverName);
                client.stop().then(() => done());
            });
        });

        it('can disconnect the client on a version mismatch', (done) => {
            let reqNetHandler = new NetHandler(socketClient);
            let reqHandshake = new HandshakeMessage(reqNetHandler);
            reqHandshake.version = 'MISMATCH';

            client.start();
            reqNetHandler.send(reqHandshake);
            reqNetHandler.onMessage(MessageType.PermanentDisconnect, (msg: Message) => {
                let dcMsg = new PermanentDisconnectMessage(reqNetHandler).encapsulate(msg);
                expect(dcMsg.machineReason).to.equal(DisconnectMachineReason.VersionMismatch);
                expect(client.connected).to.equal(false);
                done();
            });
        });
    });

    describe('authentication', () => {
        let userdata: any = {
            username: 'test_username',
            tokens: [{
                token: crypto.randomBytes(32).toString('hex'),
                created: 0
            }]
        };

        let dbMock: DbMock;
        let reqNetHandler: NetHandler;

        beforeEach((done) => {
            dbMock = new DbMock(app);

            async.series([
                (callback: (...args: any[]) => void) => setTimeout(callback, 10), // Delay so socketClient can establish
                (callback: Function) => dbMock.run().then(() => callback()), // Set up DB for testing
                (callback: Function) => { // Set up a User obj for testing
                    let userObj = new UserObj(app);
                    userdata['objId'] = userObj._id;
                    userObj.name = userdata['username'];
                    userObj.save().then(() => callback());
                },
                (callback: Function) => app.collections['userdata'].insertOne(userdata).then(() => callback()),
                (callback: Function) => {
                    reqNetHandler = new NetHandler(socketClient);
                    client.start();

                    // Handshake
                    let reqHandshake = new HandshakeMessage(reqNetHandler);
                    reqHandshake.version = App.VERSION;

                    reqNetHandler.send(reqHandshake).then((reply: Message) => {
                        callback();
                    });
                }
            ], done);
        });

        afterEach(() => client.stop());

        it('can authenticate successfully', (done) => {
            // Craft a new authentication message
            let authMsg = new AuthMessage(reqNetHandler);
            authMsg.username = 'test_username';
            authMsg.token = userdata.tokens[0].token;

            reqNetHandler.send(authMsg).then((reply: Message) => {
                let statusMsg = (new StatusMessage(reqNetHandler)).encapsulate(reply);
                expect(statusMsg.success).to.equal(true);
                done();
            }).catch(done);
        });

        it('can fail to authenticate on non-existant user', (done) => {
            // Craft a new authentication message
            let authMsg = new AuthMessage(reqNetHandler);
            authMsg.username = 'non-existant';
            authMsg.token = userdata.tokens[0].token;

            reqNetHandler.send(authMsg).then((reply: Message) => {
                let statusMsg = (new StatusMessage(reqNetHandler)).encapsulate(reply);
                expect(statusMsg.success).to.equal(false);
                done();
            }).catch(done);
        });

        it('can fail to authenticate on token mismatch', (done) => {
            // Craft a new authentication message
            let authMsg = new AuthMessage(reqNetHandler);
            authMsg.username = 'test_username';
            authMsg.token = crypto.randomBytes(32).toString('hex');

            reqNetHandler.send(authMsg).then((reply: Message) => {
                let statusMsg = (new StatusMessage(reqNetHandler)).encapsulate(reply);
                expect(statusMsg.success).to.equal(false);
                done();
            }).catch(done);
        });
    });

    describe('obj posting', () => {
        let dbMock: DbMock;
        let reqNetHandler: NetHandler;
        let userObj: UserObj;

        let userdata: any = {
            username: 'test_username',
            tokens: [{
                token: crypto.randomBytes(32).toString('hex'),
                created: 0
            }]
        };

        beforeEach((done) => {
            dbMock = new DbMock(app);
            userObj = new UserObj(app);
            dbMock.fixture[0].ownerId = userObj._id;

            async.series([
                (callback) => setTimeout(callback, 10), // Delay so socketClient can establish
                (callback) => dbMock.run().then(() => callback()), // Set up DB for testing
                (callback: Function) => { // Set up a User obj for testing
                    userdata['objId'] = userObj._id;
                    userObj.name = userdata['username'];
                    userObj.save().then(() => callback());
                },
                (callback: Function) => app.collections['userdata'].insertOne(userdata).then(() => callback()),
                (callback) => {
                    reqNetHandler = new NetHandler(socketClient);
                    client.start();

                    // Handshake
                    let reqHandshake = new HandshakeMessage(reqNetHandler);
                    reqHandshake.version = App.VERSION;

                    reqNetHandler.send(reqHandshake).then((reply: Message) => {
                        callback();
                    });
                },
                (callback) => {
                    // Authenticate the client
                    // Craft a new authentication message
                    let authMsg = new AuthMessage(reqNetHandler);
                    authMsg.username = 'test_username';
                    authMsg.token = userdata.tokens[0].token;

                    reqNetHandler.send(authMsg).then((reply: Message) => {
                        callback();
                    }).catch(callback);
                }
            ], done);
        });

        afterEach((done) => {
            client.stop().then(() => done()).catch((err) => done(err))
        });

        it('can handle a single new obj post', (done) => {
            let obj: IBoard = {
                _id: '1_TEST',
                parentIds: [],
                ownerId: '1_me',
                perms: _.cloneDeep(DefaultObjPerms),
                ctime: 0,
                mtime: 0,
                xtime: 0,
                rev: 0,

                name: 'testtest',
                description: '',
                over18: false
            };

            reqNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                let objMsg = (new ObjMessage(reqNetHandler)).encapsulate(msg);
                expect(objMsg.objs).to.have.lengthOf(1);
                done();
            });

            let objMsg = new ObjMessage(reqNetHandler);
            objMsg.objs = [obj];
            reqNetHandler.send(objMsg).catch((err) => done(err));
        });


        it('can return a failed status on a validation failure', (done) => {
            let obj: {} = {
                _id: '1_TEST',
                parentIds: [],
                ownerId: '1_me',
                perms: _.cloneDeep(DefaultObjPerms),
                ctime: 0,
                mtime: 0,
                xtime: 0,
                rev: 0,

                name: 4, // Number for a name?
                description: '',
                over18: false
            };

            reqNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                done(new Error('No objs should have been sent back'));
            });

            reqNetHandler.onMessage(MessageType.Status, (msg: Message) => {
                let statusMsg = (new StatusMessage(reqNetHandler)).encapsulate(msg);
                expect(statusMsg.success).to.equal(false);
                done();
            });

            let objMsg = new ObjMessage(reqNetHandler);
            objMsg.objs = [<IBoard>obj];
            reqNetHandler.send(objMsg).catch((err) => done(err));
        });

        it('can update an existing obj', (done) => {
            let obj: IBoard = _.cloneDeep(dbMock.fixture[0]) as IBoard;
            obj.name = 'board_new_name';
            obj.rev++;

            reqNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                let objMsg = (new ObjMessage(reqNetHandler)).encapsulate(msg);
                obj.mtime = objMsg.objs[0].mtime;
                expect(objMsg.objs[0]).to.eql(obj);

                app.obj(obj._id).then((dbObj: Obj) => {
                    expect(dbObj.getProps()).to.eql(obj);
                    done();
                });
            });

            let objMsg = new ObjMessage(reqNetHandler);
            objMsg.objs = [<IBoard>obj];
            reqNetHandler.send(objMsg).catch((err) => done(err));
        });

        it('can update the xtime properties of the Objs parents', (done) => {
            let obj: IBoard = {
                _id: '1_TEST',
                parentIds: [dbMock.fixture[1]._id],
                ownerId: '1_me',
                perms: _.cloneDeep(DefaultObjPerms),
                ctime: 0,
                mtime: 0,
                xtime: 0,
                rev: 0,

                name: 'testtest',
                description: '',
                over18: false
            };

            reqNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                let objMsg = (new ObjMessage(reqNetHandler)).encapsulate(msg);
                app.obj(obj.parentIds[0]).then((parent: Obj) => {
                    let time = +new Date() / 1000;

                    expect(parent.xtime).to.be.within(time - 10, time + 10);
                    done();
                }).catch((err) => done(err));
            });

            let objMsg = new ObjMessage(reqNetHandler);
            objMsg.objs = [obj];
            reqNetHandler.send(objMsg).catch((err) => done(err));
        });


        it('can return a failed status on an unauthorised obj update', (done) => {
            let obj: IBoard = _.cloneDeep(dbMock.fixture[1]) as IBoard;
            obj.name = 'board_new_name';
            obj.perms.all.modify = true;
            obj.rev++;

            reqNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                done(new Error('No objs should have been sent back'));
            });

            reqNetHandler.onMessage(MessageType.Status, (msg: Message) => {
                let statusMsg = (new StatusMessage(reqNetHandler)).encapsulate(msg);
                expect(statusMsg.success).to.equal(false);

                app.obj(obj._id).then((dbObj: Obj) => {
                    expect(dbObj.getProps()).to.eql(dbMock.fixture[1]);
                    done();
                }).catch((err) => done(err));
            });

            let objMsg = new ObjMessage(reqNetHandler);
            objMsg.objs = [<IBoard>obj];
            reqNetHandler.send(objMsg).catch((err) => done(err));
        });

        it('can return a failed status when the user is not permitted to add an Obj to one or more of it\'s parents', (done) => {
            let obj = new ObjCommon();
            obj.parentIds = [dbMock.fixture[dbMock.fixture.length - 1]._id];

            reqNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                done(new Error('No objs should have been sent back'));
            });

            reqNetHandler.onMessage(MessageType.Status, (msg: Message) => {
                let statusMsg = (new StatusMessage(reqNetHandler)).encapsulate(msg);
                expect(statusMsg.success).to.equal(false);

                app.obj(obj._id).then((dbObj: Obj) => {
                    done(new Error('obj should not have been inserted into DB'));
                }).catch((err) => {
                    done();
                });
            });

            let objMsg = new ObjMessage(reqNetHandler);
            objMsg.objs = [obj];
            reqNetHandler.send(objMsg).catch((err) => done(err));
        });

        it('can return a failed status when attempting to post too often', async () => {
            let obj = new PostObj(app);
            let objMsg = new ObjMessage(reqNetHandler);
            objMsg.objs = [obj.getProps()];
            let res = await reqNetHandler.send(objMsg);
            expect(res.type).to.equal(MessageType.Obj);

            obj = new PostObj(app);
            objMsg = new ObjMessage(reqNetHandler);
            objMsg.objs = [obj.getProps()];
            res = await reqNetHandler.send(objMsg);
            expect(res.type).to.equal(MessageType.Status);
            expect(res.fields[MessageField.Success]).to.be.false;
        });
    });

    describe('unauth', () => {
        let dbMock: DbMock;
        let reqNetHandler: NetHandler;
        let userObj: UserObj;

        let userdata: any = {
            username: 'test_username',
            tokens: [{
                token: crypto.randomBytes(32).toString('hex'),
                created: 0
            }]
        };

        beforeEach((done) => {
            dbMock = new DbMock(app);
            userObj = new UserObj(app);
            dbMock.fixture[0].ownerId = userObj._id;

            async.series([
                (callback) => setTimeout(callback, 10), // Delay so socketClient can establish
                (callback) => dbMock.run().then(() => callback()), // Set up DB for testing
                (callback: Function) => { // Set up a User obj for testing
                    userdata['objId'] = userObj._id;
                    userObj.name = userdata['username'];
                    userObj.save().then(() => callback());
                },
                (callback: Function) => app.collections['userdata'].insertOne(userdata).then(() => callback()),
                (callback) => {
                    reqNetHandler = new NetHandler(socketClient);
                    client.start();

                    // Handshake
                    let reqHandshake = new HandshakeMessage(reqNetHandler);
                    reqHandshake.version = App.VERSION;

                    reqNetHandler.send(reqHandshake).then((reply: Message) => {
                        callback();
                    });
                },
                (callback) => {
                    // Authenticate the client
                    // Craft a new authentication message
                    let authMsg = new AuthMessage(reqNetHandler);
                    authMsg.username = 'test_username';
                    authMsg.token = userdata.tokens[0].token;

                    reqNetHandler.send(authMsg).then((reply: Message) => {
                        callback();
                    }).catch(callback);
                }
            ], done);
        });

        afterEach((done) => {
            client.stop().then(() => done()).catch((err) => done(err))
        });

        it('can respond with a successful status message', async () => {
            // Craft a new authentication message
            let unAuthMsg = new UnAuthMessage(reqNetHandler);

            let reply = await reqNetHandler.send(unAuthMsg);
            let statusMsg = (new StatusMessage(reqNetHandler)).encapsulate(reply);

            expect(statusMsg.success).to.equal(true);
        });

        it('can set authenticated to false', async () => {
            // Craft a new authentication message
            let unAuthMsg = new UnAuthMessage(reqNetHandler);
            await reqNetHandler.send(unAuthMsg);

            expect(client.authenticated).to.equal(false);
        });

        it('can set userObj to null', async () => {
            // Craft a new authentication message
            let unAuthMsg = new UnAuthMessage(reqNetHandler);
            await reqNetHandler.send(unAuthMsg);

            expect(client.userObj).to.equal(null);
        });

        it('can emit a deauth event', (done) => {
            // Craft a new authentication message
            let unAuthMsg = new UnAuthMessage(reqNetHandler);

            client.on('unauth', () => done());

            reqNetHandler.send(unAuthMsg);
        });
    });

    describe('authentication checks', () => {
        let dbMock: DbMock;
        let reqNetHandler: NetHandler;
        let userObj: UserObj;

        beforeEach((done) => {
            dbMock = new DbMock(app);
            userObj = new UserObj(app);
            dbMock.fixture[0].ownerId = userObj._id;

            async.series([
                (callback) => setTimeout(callback, 10), // Delay so socketClient can establish
                (callback) => dbMock.run().then(() => callback()), // Set up DB for testing
                (callback) => {
                    reqNetHandler = new NetHandler(socketClient);
                    client.start();

                    // Handshake
                    let reqHandshake = new HandshakeMessage(reqNetHandler);
                    reqHandshake.version = App.VERSION;

                    reqNetHandler.send(reqHandshake).then((reply: Message) => {
                        callback();
                    });
                }
            ], done);
        });

        afterEach((done) => {
            client.stop().then(() => done()).catch((err) => done(err))
        });

        it('cannot post an Obj when unauthenticated', async () => {
            let obj: IBoard = {
                _id: '1_TEST',
                parentIds: [],
                ownerId: '1_me',
                perms: _.cloneDeep(DefaultObjPerms),
                ctime: 0,
                mtime: 0,
                xtime: 0,
                rev: 0,

                name: 'testtest',
                description: '',
                over18: false
            };

            reqNetHandler.onMessage(MessageType.Obj, (msg: Message) => {
                throw new Error('no Obj should have been received');
            });

            let objMsg = new ObjMessage(reqNetHandler);
            objMsg.objs = [obj];
            let reply = await reqNetHandler.send(objMsg);
            expect(reply.type).to.equal(MessageType.Status);
            let statusReply = new StatusMessage(reqNetHandler).encapsulate(reply);
            expect(statusReply.success).to.equal(false);
        });
    });

    describe('obj revocation', () => {
        let dbMock: DbMock;
        let reqNetHandler: NetHandler;
        let userObj: UserObj;

        let userdata: any = {
            username: 'test_username',
            tokens: [{
                token: crypto.randomBytes(32).toString('hex'),
                created: 0
            }]
        };

        beforeEach((done) => {
            dbMock = new DbMock(app);
            userObj = new UserObj(app);
            dbMock.fixture[0].ownerId = userObj._id;

            async.series([
                (callback) => setTimeout(callback, 10), // Delay so socketClient can establish
                (callback) => dbMock.run().then(() => callback()), // Set up DB for testing
                (callback: Function) => { // Set up a User obj for testing
                    userdata['objId'] = userObj._id;
                    userObj.name = userdata['username'];
                    userObj.save().then(() => callback());
                },
                (callback: Function) => app.collections['userdata'].insertOne(userdata).then(() => callback()),
                (callback) => {
                    reqNetHandler = new NetHandler(socketClient);
                    client.start();

                    // Handshake
                    let reqHandshake = new HandshakeMessage(reqNetHandler);
                    reqHandshake.version = App.VERSION;

                    reqNetHandler.send(reqHandshake).then((reply: Message) => {
                        callback();
                    });
                },
                (callback) => {
                    // Authenticate the client
                    // Craft a new authentication message
                    let authMsg = new AuthMessage(reqNetHandler);
                    authMsg.username = 'test_username';
                    authMsg.token = userdata.tokens[0].token;

                    reqNetHandler.send(authMsg).then((reply: Message) => {
                        callback();
                    }).catch(callback);
                }
            ], done);
        });

        afterEach(async () => {
            await client.stop();
        });

        it('can send a RmObjMessage for a single non-existant Obj', (done) => {
            reqNetHandler.onMessage(MessageType.RmObj, (msg: Message) => {
                let rmObjMessage = new RmObjMessage(reqNetHandler).encapsulate(msg);
                expect(rmObjMessage.objIds).to.eql(['1_NONEXIST']);
                done();
            });

            let objCacheStateMsg = new ObjCacheStateMessage(reqNetHandler);
            objCacheStateMsg.objCacheState = {
                [dbMock.fixture[0]._id]: 0,
                '1_NONEXIST': 123
            };
            reqNetHandler.send(objCacheStateMsg);
        });

        it('can send a RmObjMessage for a multiple non-existant Objs', (done) => {
            reqNetHandler.onMessage(MessageType.RmObj, (msg: Message) => {
                let rmObjMessage = new RmObjMessage(reqNetHandler).encapsulate(msg);
                expect(rmObjMessage.objIds).to.have.length(2);
                expect(rmObjMessage.objIds).to.contain('1_NONEXIST');
                expect(rmObjMessage.objIds).to.contain('2_NONEXIST');
                done();
            });

            let objCacheStateMsg = new ObjCacheStateMessage(reqNetHandler);
            objCacheStateMsg.objCacheState = {
                [dbMock.fixture[0]._id]: 0,
                '1_NONEXIST': 123,
                '2_NONEXIST': 123
            };
            reqNetHandler.send(objCacheStateMsg);
        });
    });

    describe('obj removal', () => {
        let dbMock: DbMock;
        let reqNetHandler: NetHandler;
        let userObj: UserObj;

        let userdata: any = {
            username: 'test_username',
            tokens: [{
                token: crypto.randomBytes(32).toString('hex'),
                created: 0
            }]
        };

        beforeEach((done) => {
            dbMock = new DbMock(app);
            userObj = new UserObj(app);
            dbMock.fixture[0].ownerId = userObj._id;

            async.series([
                (callback) => setTimeout(callback, 10), // Delay so socketClient can establish
                (callback) => dbMock.run().then(() => callback()), // Set up DB for testing
                (callback: Function) => { // Set up a User obj for testing
                    userdata['objId'] = userObj._id;
                    userObj.name = userdata['username'];
                    userObj.save().then(() => callback());
                },
                (callback: Function) => app.collections['userdata'].insertOne(userdata).then(() => callback()),
                (callback) => {
                    reqNetHandler = new NetHandler(socketClient);
                    client.start();

                    // Handshake
                    let reqHandshake = new HandshakeMessage(reqNetHandler);
                    reqHandshake.version = App.VERSION;

                    reqNetHandler.send(reqHandshake).then((reply: Message) => {
                        callback();
                    });
                },
                (callback) => {
                    // Authenticate the client
                    // Craft a new authentication message
                    let authMsg = new AuthMessage(reqNetHandler);
                    authMsg.username = 'test_username';
                    authMsg.token = userdata.tokens[0].token;

                    reqNetHandler.send(authMsg).then((reply: Message) => {
                        callback();
                    }).catch(callback);
                }
            ], done);
        });

        afterEach((done) => {
            client.stop().then(() => done()).catch((err) => done(err))
        });

        it('can remove the Objs specified from the DB', (done) => {
            reqNetHandler.onMessage(MessageType.RmObj, async (msg: Message) => {
                try {
                    await app.obj(dbMock.fixture[0]._id);
                    throw new Error('No obj should have been retrieved (app.obj should have failed)');
                } catch(e) {
                    if(e.name !== 'ObjNotFoundError') return done(e);
                }

                done();
            });

            let rmObjMsg = new RmObjMessage(reqNetHandler);
            rmObjMsg.objIds = [dbMock.fixture[0]._id];
            reqNetHandler.send(rmObjMsg).catch((err) => done(err));
        });

        it('can reply with an RmObjMessage loaded with Obj IDs on successful removal', (done) => {
            reqNetHandler.onMessage(MessageType.RmObj, (msg: Message) => {
                let reply = (new RmObjMessage(reqNetHandler)).encapsulate(msg);
                expect(reply.objIds).to.eql([dbMock.fixture[0]._id]);
                done();
            });

            let rmObjMsg = new RmObjMessage(reqNetHandler);
            rmObjMsg.objIds = [dbMock.fixture[0]._id];
            reqNetHandler.send(rmObjMsg).catch((err) => done(err));
        });

        it('can reply with a failed StatusMessage if one of the Objs do not exist', (done) => {
            reqNetHandler.onMessage(MessageType.Status, (msg: Message) => {
                let reply = (new StatusMessage(reqNetHandler)).encapsulate(msg);
                expect(reply.success).to.equal(false);
                done();
            });

            let rmObjMsg = new RmObjMessage(reqNetHandler);
            rmObjMsg.objIds = ['NOEXIST'];
            reqNetHandler.send(rmObjMsg).catch((err) => done(err));
        });
    });
});
