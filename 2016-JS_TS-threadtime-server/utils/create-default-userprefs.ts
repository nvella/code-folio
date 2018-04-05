import * as _ from 'lodash';
import {MongoClient, Collection} from 'mongodb';

import {Obj, ObjPermsTemplates, ObjType, IUserPrefs} from "@threadtime/threadtime-common";

async function main() {
    if(!process.env.DB_URI) {
        console.error('usage: node create-default-userprefs.js');
        console.error('ensure DB_URI is set to the relevant DB uri');
        process.exit(1);
    }

    let dbUri       = process.env.DB_URI;

    console.log('creating default user prefs Obj');

    console.log(`connecting to DB...`);
    let db = await MongoClient.connect(dbUri);
    let collections = {
        objects: db.collection('objects')
    };

    console.log(`inserting userprefs object`);
    let userPrefsObj: any = {
        ...(() => {
            let obj = new Obj();
            obj.type = ObjType.UserPrefs;
            return obj;
        })().getProps(),
        prefs: _.cloneDeep(ObjPermsTemplates.board),
        following: []
    };
    await collections['objects'].insertOne(userPrefsObj);

    console.log(`closing database`);
    await db.close();

    console.log(`default userprefs ID: ${userPrefsObj._id}`);
}

main().catch((err) => {
    console.error(`error: ${err}`);
    process.exit(1);
});
