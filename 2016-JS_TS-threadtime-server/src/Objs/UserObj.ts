import { Obj } from './';
import { App } from '../';
import { ObjType, IUser } from "@threadtime/threadtime-common";

export class UserObj extends Obj implements IUser {
    name: string;
    admin: boolean;

    constructor(app: App, id?: string) {
        super(app, id);

        this.name = '';
        this.admin = false;

        this.type = ObjType.User;
    }

    /**
     * Copy the properties of another Obj into this one
     * @param obj Source object
     * @returns {UserObj} This object
     */
    encapsulate(obj: Obj): UserObj {
        this.consume(obj);
        return this;
    }
}