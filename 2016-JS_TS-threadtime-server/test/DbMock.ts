import * as _ from 'lodash';
import * as async from 'async';
import * as mongodb from 'mongodb';

import {IObj, IBoard, ObjType, DefaultObjPerms, IUser} from "@threadtime/threadtime-common";
import { App } from '../src';

export class DbMock {
    private app: App;
    fixture: IObj[];

    static DB_FIXTURE: IObj[] = [
        <IBoard>{
            _id: `${ObjType.Board}_TEST1`,
            ownerId: `${ObjType.User}_USER1`,
            parentIds: [],
            perms: _.cloneDeep(DefaultObjPerms),
            ctime: 1,
            mtime: 1,
            xtime: 0,
            rev: 0,

            name: 'board_name',
            description: '',
            over18: false
        },

            <IBoard>{
                _id: `${ObjType.Board}_TEST2`,
                ownerId: '1_TEST2',
                parentIds: [`${ObjType.Board}_TEST1`],
                perms: _.cloneDeep(DefaultObjPerms),
                ctime: 1,
                mtime: 1,
                xtime: 0,
                rev: 0,

                name: 'child_board',
                description: '',
                over18: false
            },

                <IBoard>{
                    _id: `${ObjType.Board}_TEST3`,
                    ownerId: '1_TEST2',
                    parentIds: [`${ObjType.Board}_TEST2`],
                    perms: _.cloneDeep(DefaultObjPerms),
                    ctime: 1,
                    mtime: 1,
                    xtime: 0,
                    rev: 0,

                    name: '2nd_lvl_child_board_1',
                    description: '',
                    over18: false
                },

                <IBoard>{
                    _id: `${ObjType.Board}_TEST4`,
                    ownerId: '1_TEST2',
                    parentIds: [`${ObjType.Board}_TEST2`],
                    perms: _.cloneDeep(DefaultObjPerms),
                    ctime: 1,
                    mtime: 1,
                    xtime: 1,
                    rev: 0,

                    name: '2nd_lvl_child_board_2',
                    description: '',
                    over18: false
                },

        <IUser>{
            _id: `${ObjType.User}_USER1`,
            ownerId: null,
            parentIds: [],
            perms: _.cloneDeep(DefaultObjPerms),
            ctime: 1,
            mtime: 1,
            xtime: 0,
            rev: 0,

            name: 'user_1',
            admin: false
        },

        <IUser>{
            _id: `${ObjType.User}_USER2`,
            ownerId: null,
            parentIds: [],
            perms: _.cloneDeep(DefaultObjPerms),
            ctime: 1,
            mtime: 1,
            xtime: 0,
            rev: 0,

            name: 'user_2',
            admin: false
        },

        <IBoard>{
            _id: `${ObjType.Board}_TEST5`,
            ownerId: null,
            parentIds: [],
            perms: {
                owner: DefaultObjPerms.owner,
                others: DefaultObjPerms.others,
                all: {
                    modify: false,
                    view: false,
                    children: {
                        [ObjType.Generic]: {
                            add: false,
                            rm: false
                        }
                    }
                }
            },
            ctime: 1,
            mtime: 1,
            xtime: 0,
            rev: 0,

            name: 'board_2',
            description: '',
            over18: false
        }
    ];

    constructor(app: App, fixture?: IObj[]) {
        this.app = app;
        if(fixture) {
            this.fixture = _.cloneDeep(fixture);
        } else {
            this.fixture = _.cloneDeep(DbMock.DB_FIXTURE);
        }
    }

    run(): Promise<void> {
        return new Promise<void>((resolve) => {
            async.series([
                (callback) => { // drop collections
                    async.forEachOf(this.app.collections, (col: mongodb.Collection, key: string, callback: any) => {
                        col.drop(() => callback());
                    }, callback);
                },
                (callback) => { // insert fixture data
                    async.each(this.fixture, (doc: Object, callback: any) => {
                        this.app.collections['objects'].insertOne(doc, callback);
                    }, callback);
                }
            ], () => resolve());
        });
    }
}