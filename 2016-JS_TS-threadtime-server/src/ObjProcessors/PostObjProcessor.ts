import {App} from "../App";
import {Client} from "../Client";
import {Obj} from "../Objs/Obj";
import {ObjProcessor} from "./ObjProcessor";

export class PostObjProcessor extends ObjProcessor {
    postRateLimitMs: number = 5000;
    lastPost: number = 0;

    doOnCreate(obj: Obj): void {
        super.doOnCreate(obj);

        if((+ new Date()) - this.lastPost < this.postRateLimitMs) throw new Error('Too fast between posts');
        this.lastPost = + new Date();
    }
}