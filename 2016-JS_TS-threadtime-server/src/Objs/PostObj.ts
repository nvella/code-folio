import { Obj } from './';
import { App } from '../';
import { ObjType, IPost } from "@threadtime/threadtime-common";

export class PostObj extends Obj implements IPost {
    title: string | null;
    body: string | null;
    url: string | null;
    ups: number;

    constructor(app: App, id?: string) {
        super(app, id);

        this.title = null;
        this.body = null;
        this.url = null;
        this.ups = 0;

        this.type = ObjType.Post;
    }

    /**
     * Copy the properties of another Obj into this one
     * @param obj Source object
     * @returns {UserObj} This object
     */
    encapsulate(obj: Obj): PostObj {
        this.consume(obj);
        return this;
    }
}