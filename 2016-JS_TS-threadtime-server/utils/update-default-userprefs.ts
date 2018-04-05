import * as _ from 'lodash';
import {MongoClient, Collection} from 'mongodb';

import {Obj, ObjPermsTemplates, ObjType, IUserPrefs} from "@threadtime/threadtime-common";

async function main() {
    if(!process.env.DB_URI || !process.env.USERPREFS_ID || !process.argv[2]) {
        console.error('usage: node update-default-userprefs.js userprefs-json');
        console.error('ensure DB_URI is set to the relevant DB uri');
        console.error('ensure USERPREFS_ID is set to the default userprefs obj');
        process.exit(1);
    }

    let dbUri       = process.env.DB_URI;
    let userPrefsId = process.env.USERPREFS_ID;
    let userprefs   = JSON.parse(process.argv[2]);

    console.log('updating default user prefs Obj');

    console.log(`connecting to DB...`);
    let db = await MongoClient.connect(dbUri);
    let collections = {
        objects: db.collection('objects')
    };

    console.log(`updating userprefs object`);
    await collections['objects'].updateOne(
        {
            _id: userPrefsId
        },
        {
            $set: userprefs,
            $inc: {rev: 1}
        }
    );

    console.log(`closing database`);
    await db.close();
}

main().catch((err) => {
    console.error(`error: ${err}`);
    process.exit(1);
});