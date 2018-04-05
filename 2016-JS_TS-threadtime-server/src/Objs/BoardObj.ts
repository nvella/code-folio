import { Obj } from './';
import { App } from '../';
import { ObjType, IBoard } from "@threadtime/threadtime-common";

export class BoardObj extends Obj implements IBoard {
    name: string;
    description: string;
    over18: boolean;

    constructor(app: App, id?: string) {
        super(app, id);

        this.name = '';
        this.description = '';
        this.over18 = false;

        this.type = ObjType.Board;
    }

    /**
     * Copy the properties of another Obj into this one
     * @param obj Source object
     * @returns {UserObj} This object
     */
    encapsulate(obj: Obj): BoardObj {
        this.consume(obj);
        return this;
    }
}