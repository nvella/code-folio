import {App} from "../App";
import {Client} from "../Client";
import {Obj} from "../Objs/Obj";

export class ObjProcessor {
    constructor(private app: App, private client: Client) { }

    doAlways(obj: Obj): void {
        // Set the Obj's owner to the User currently authenticated on the Client
        obj.ownerId = this.client.userObj._id;
    }

    doOnModify(obj: Obj): void {
        this.doAlways(obj);

        obj.mtime = Math.floor(+ new Date() / 1000);
    }

    doOnCreate(obj: Obj): void {
        this.doOnModify(obj);

        obj.ctime = obj.xtime = Math.floor(+ new Date() / 1000);
    }
}