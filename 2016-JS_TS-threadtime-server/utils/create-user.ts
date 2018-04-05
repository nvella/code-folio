import * as _ from 'lodash';
import * as bcrypt from 'bcrypt';
import {MongoClient, Db, Collection} from 'mongodb';

import {Obj, IUser, IUserPrefs, ObjPermsTemplates, ObjType, IUserData} from "@threadtime/threadtime-common";

async function main() {
    if(process.argv.length < 5) {
        console.error('usage: node create-user.js dbUri username password');
        process.exit(1);
    }

    let dbUri    = process.argv[2];
    let username = process.argv[3];
    let password = process.argv[4];

    console.log('creating user');
    console.log(`    username=${username}`);
    console.log(`    password=${password}`);

    console.log(`connecting to DB...`);
    let db = await (new Promise<Db>((resolve, reject) => {
        MongoClient.connect(dbUri, (err: any, db: Db) => {
            if(err) reject(err);
            resolve(db);
        });
    }));

    console.log(`connecting collections...`);
    let collectionNames = ['objects', 'userdata'];
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

    console.log(`generating salt...`);
    let salt = await new Promise<string>((resolve, reject) => bcrypt.genSalt((err, salt) => {
        if(err) reject(err);
        resolve(salt);
    }));
    console.log(`    salt=${salt}`);

    console.log(`hashing password...`);
    let hash = await new Promise<string>((resolve, reject) => bcrypt.hash(password, salt, (err, hash) => {
        if(err) reject(err);
        resolve(hash);
    }));
    console.log(`    hash=${hash}`);
    
    console.log(`inserting user object`);
    let userObj: IUser = (() => { let obj = new Obj(); obj.type = ObjType.User; return obj; })().getProps() as any;
    userObj.name = username;
    userObj.perms = _.cloneDeep(ObjPermsTemplates.user);
    await collections['objects'].insertOne(userObj);

    console.log(`inserting userdata...`);
    let userdata: IUserData = {
        _id: null,
        username: username,
        email: null,
        bcrypt: hash,
        tokens: [],
        objId: userObj._id
    };
    await collections['userdata'].insertOne(userdata);

    console.log(`inserting userprefs object`);
    let userPrefsObj: IUserPrefs = (() => { let obj = new Obj(); obj.type = ObjType.UserPrefs; return obj; })().getProps() as any;
    userPrefsObj.following = [];
    userPrefsObj.ownerId = userObj._id;
    userPrefsObj.parentIds = [userObj._id];
    userPrefsObj.perms = _.cloneDeep(ObjPermsTemplates.userPrefs);
    await collections['objects'].insertOne(userPrefsObj);

    console.log(`closing database`);
    await new Promise<void>((resolve) => db.close(() => resolve()))
}

main().catch((err) => {
    console.error(`error: ${err}`);
    process.exit(1);
});
