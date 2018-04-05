import * as _ from 'lodash';
import {MongoClient, Db, Collection} from 'mongodb';

import {Obj, ObjPermsTemplates, ObjType, IBoard} from "@threadtime/threadtime-common";

async function main() {
    if(process.argv.length < 6) {
        console.error('usage: node create-board.js dbUri name description over18');
        process.exit(1);
    }

    let dbUri       = process.argv[2];
    let name        = process.argv[3];
    let description = process.argv[4];
    let over18      = process.argv[5] === 'true';

    console.log('creating board');
    console.log(`    name=${name}`);
    console.log(`    description=${description}`);
    console.log(`    over18=${over18}`);

    console.log(`connecting to DB...`);
    let db = await (new Promise<Db>((resolve, reject) => {
        MongoClient.connect(dbUri, (err: any, db: Db) => {
            if(err) reject(err);
            resolve(db);
        });
    }));

    console.log(`connecting collections...`);
    let collectionNames = ['objects'];
    let collections: {[name: string]: Collection} = {};
    await Promise.all(collectionNames.map((name) => {
        return new Promise((resolve, reject) => {
            console.log(`    ${name}`);
            db.collection(name, (err: any, col: Collection) => {
                if(err) reject(err);
                collections[name] = col;
                resolve();
            });

        });
    }));

    console.log(`inserting board object`);
    let boardObj: IBoard = (() => { let obj = new Obj(); obj.type = ObjType.Board; return obj; })().getProps() as any;
    boardObj.name = name;
    boardObj.description = description;
    boardObj.over18 = over18;
    boardObj.perms = _.cloneDeep(ObjPermsTemplates.board);
    await collections['objects'].insertOne(boardObj);

    console.log(`closing database`);
    await new Promise<void>((resolve) => db.close(() => resolve()))
}

main().catch((err) => {
    console.error(`error: ${err}`);
    process.exit(1);
});