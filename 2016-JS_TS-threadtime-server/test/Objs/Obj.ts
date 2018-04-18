/// <reference path="../../node_modules/@types/mocha/index.d.ts" />

import { expect } from 'chai';
import * as mongodb from 'mongodb';
import * as async from 'async';
import * as _ from 'lodash';

import { DbMock } from '../DbMock';

import { App, Obj } from '../../src/';
import { ObjType, IObj, IBoard, ObjSchemaMap } from '@threadtime/threadtime-common';
import {TestPortNumber} from "../TestPortNumber";

describe('Obj', () => {
    let app: App;
    let obj: Obj;
    let dbMock: DbMock;

    beforeEach(async () => {
        app = new App({...(App.DEFAULT_CONFIG), port: TestPortNumber()});
        dbMock = new DbMock(app);

        await app.start();
        await dbMock.run();
    });

    afterEach(() => app.stop());

    describe('get/set', () => {
        it('can get the owner as Obj from ownerId', () => {
            obj = new Obj(app, `${ObjType.Board}TEST`);
            obj.ownerId = '1TEST_OWNER';
            expect(obj.owner._id).to.equal('1TEST_OWNER');
        });

        it('can set ownerId given an Obj through owner', () => {
            obj = new Obj(app, `${ObjType.Board}TEST`);
            let owner_obj = new Obj(app, `${ObjType.Board}TEST_OWNER`);
            obj.owner = owner_obj;
            expect(obj.ownerId).to.equal(owner_obj._id);
        });
    });

    describe('parent', () => {
        it('can get parents as Obj from parentIds', () => {
            obj = new Obj(app, `${ObjType.Board}TEST`);
            obj.parentIds = ['1TEST_OWNER', '1TEST_PARENT2'];
            for(let i in obj.parentIds) {
                expect(obj.parents[i]).to.be.an.instanceof(Obj);
                expect(obj.parents[i]._id).to.equal(obj.parentIds[i]);
            }
        });
    });

    describe('#load', () => {
        let fixture: any;

        beforeEach(() => {
            fixture = DbMock.DB_FIXTURE[0];
            obj = new Obj(app, fixture['_id']);
        });

        it('can load properties from the document into the object', (done) => {
            obj.load().then(() => {
                _.forEach(fixture, (val: any, key: string) => {
                    expect((<any>obj)[key]).to.eql(val);
                });
                done();
            }).catch((err) => {
                done(err);
            });
        });

        it('can reject if the obj does not exist in the DB', (done) => {
            obj._id = '1DOES_NOT_EXIST';
            obj.load().then(() => {
                done(new Error('test: obj#load executed successfully when it should not have'));
            }).catch((err: Error) => {
                expect(err.name).to.equal('ObjNotFoundError');
                done();
            });
        });
    });

    describe('#save', () => {
        beforeEach(() => obj = new Obj(app, `${ObjType.Board}_TEST_SAVE`));

        it('can save an object to the database', (done) => {
            (<IBoard><any>obj).name = 'test_board';
            (<IBoard><any>obj).over18 = false;
            (<IBoard><any>obj).description = '';

            async.series([
                (callback) => {
                    obj.save().then(() => callback()).catch(() => callback());
                },
                (callback) => { // Check saving
                    app.collections['objects'].find({_id: obj._id}).toArray((err: any, docs: any[]) => {
                        expect(docs).to.not.be.empty;

                        for(let k of ObjSchemaMap[ObjType.Board].keys) {
                            expect((<any>obj)[k]).to.eql(docs[0][k]);
                        }
                        callback();
                    });
                }
            ], done);
        });

        it('can error on validation error and not save', (done) => {
            (<IBoard><any>obj).name = 'test_board!!!'; // <-- schema violation
            (<IBoard><any>obj).over18 = false;
            (<IBoard><any>obj).description = '';

            obj.save().then(() => {
                done(new Error('a validation error should have been raised'));
            }).catch((err: Error) => {
                expect(err.name).to.equal('ValidationError');

                app.collections['objects'].find({_id: obj._id}).toArray((err: any, docs: any[]) => {
                    expect(docs).to.be.empty;
                    done();
                });
            });
        });
    });

    describe('#update', () => {
        beforeEach(() => obj = new Obj(app, `${ObjType.Generic}_TEST_UPDATE`));

        it('can call #save', (done) => {
            obj.save = (): Promise<void> => {
                return new Promise<void>((resolve, reject) => {
                    return done();
                });
            };

            obj.update().catch((err) => done(err));
        });

        it('can emit an update with the serialized Obj onto the SystemBus', (done) => {
            app.systemBus.on('obj', (objSerialized: IObj) => {
                expect(objSerialized).to.eql(obj.getProps());
                done();
            });

            obj.update().catch((err) => done(err));
        });
    });

    describe('#remove', () => {
        let dbMock;

        beforeEach(async () => {
            dbMock = new DbMock(app);
            await dbMock.run();
            obj = new Obj(app, dbMock.fixture[0]._id);
        });

        it('can remove an Obj from the DB', async () => {
            await obj.remove();
            try {
                await app.obj(obj._id);
                throw new Error('No obj should have been retrieved (app.obj should have failed)');
            } catch(e) {
                if(e.name !== 'ObjNotFoundError') throw e;
            }
        });

        it('can emit a \'obj-remove\' event with the Obj ID onto the system bus on removal', (done) => {
            app.systemBus.on('obj-remove', (id: string) => {
                expect(id).to.equal(obj._id);
                done();
            });
            obj.remove().catch((err) => done(err));
        });
    });

    describe('#getChildren', () => {
        beforeEach(() => obj = new Obj(app, `${ObjType.Board}_TEST1`));

        it('can return a promise', () => {
            expect(obj.getChildren().then).to.be.a('function');
        });

        it('can query DB and return children as array of Obj', (done) => {
            obj.getChildren().then((parents: Obj[]) => {
                expect(parents).to.be.an.instanceof(Array);
                expect(parents).to.not.be.empty;
                expect(parents[0]._id).to.equal(`${ObjType.Board}_TEST2`);
                done();
            }).catch((err) => done(err));
        });

        it('can limit the number of results returned to a specified amount', async () => {
            obj = new Obj(app, `${ObjType.Board}_TEST2`);
            let children = await obj.getChildren(1);
            expect(children).to.have.length(1);
            expect(children[0].ownerId).to.equal(obj._id);
        });

        it('can sort by xtime descending', async () => {
            obj = new Obj(app, `${ObjType.Board}_TEST2`);
            let children = await obj.getChildren();
            expect(children).to.have.length(2);
            expect(children.map((obj) => obj._id)).to.eql(_.sortBy(dbMock.fixture.filter((iobj) => iobj.parentIds.indexOf(obj._id) >= 0), 'xtime').reverse().map((obj) => obj._id));
        });
    });

    describe('#getChildrenTree', () => {
        beforeEach(() => obj = new Obj(app, `${ObjType.Board}_TEST1`));

        it('can return a promise', () => {
            expect(obj.getChildrenTree(0).then).to.be.a('function');
        });

        it('can return nothing on zero levels', (done) => {
            obj.getChildrenTree(0).then((objs: Obj[]) => {
                expect(objs).to.be.empty;
                done();
            }).catch((err) => done(err));
        });

        it('can return one level of children; the direct descendants', (done) => {
            let childrenIds: string[] = [`${ObjType.Board}_TEST2`];

            obj.getChildrenTree(1).then((objs: Obj[]) => {
                let ids = objs.map((obj: Obj) => obj._id);
                expect(ids).to.eql(childrenIds);
                done();
            }).catch((err) => done(err));
        });

        it('can return two levels of children; the direct descendants and their children', (done) => {
            let childrenIds: string[] = [`${ObjType.Board}_TEST2`, `${ObjType.Board}_TEST3`, `${ObjType.Board}_TEST4`];

            obj.getChildrenTree(2).then((objs: Obj[]) => {
                let ids = objs.map((obj: Obj) => obj._id);
                expect(ids).to.have.members(childrenIds);
                expect(ids.length).to.equal(childrenIds.length);
                done();
            }).catch((err) => done(err));
        });

        it('can treat owners as children', (done) => {
            let childrenIds: string[] = [`${ObjType.Board}_TEST2`, `${ObjType.Board}_TEST3`, `${ObjType.Board}_TEST4`, `${ObjType.User}_USER1`];

            obj.getChildrenTree(2, [], true).then((objs: Obj[]) => {
                let ids = objs.map((obj: Obj) => obj._id);
                expect(ids).to.have.members(childrenIds);
                expect(ids.length).to.equal(childrenIds.length);
                done();
            }).catch((err) => done(err));
        });

        it('can correctly process the limits parameter and limit the Objs returned at each level', async () => {
            let childrenIds: string[] = [`${ObjType.Board}_TEST2`, `${ObjType.Board}_TEST4`];

            let objs = await obj.getChildrenTree(2, [null, 1]);
            let ids = objs.map((obj: Obj) => obj._id);
            expect(ids).to.have.members(childrenIds);
            expect(ids.length).to.equal(childrenIds.length);
        });
    });
});