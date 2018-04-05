import { Obj } from './';
import { App } from '../';
import {ObjType, IUserPrefs} from "@threadtime/threadtime-common";

export class UserPrefsObj extends Obj implements IUserPrefs {
    following: string[];

    constructor(app: App, id?: string) {
        super(app, id);

        this.following = [];

        this.type = ObjType.UserPrefs;
    }

    /**
     * Copy the properties of another Obj into this one
     * @param obj Source object
     * @returns {UserObj} This object
     */
    encapsulate(obj: Obj): UserPrefsObj {
        this.consume(obj);
        return this;
    }
}