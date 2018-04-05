import * as mongodb from 'mongodb';
import * as shortid from 'shortid';
import * as async from 'async';
import * as _ from 'lodash';
import * as Joi from 'joi';

import { IObj, ObjType, ObjSchemaMap, Obj as ObjCommon, IObjValidation } from '@threadtime/threadtime-common';
import {App} from "../App";
import {ObjNotFoundError, ValidationError as ValidationErrorLocal} from "../Errors";

// Generic object class
export class Obj extends ObjCommon implements IObj {
    private app: App;
    private collection: mongodb.Collection;

    public loaded: boolean;

    /**
     * Represents an Obj in Threadtime, server-side.
     * @param app Threadtime Server App instance
     * @param id Threadtime Obj ID
     */
    constructor(app: App, id?: string) {
        super(id);

        this.app = app;
        this.collection = this.app.collections['objects'];
        this.loaded = false;
    }

    get owner(): Obj {
        return new Obj(this.app, this.ownerId);
    }

    set owner(obj: Obj) {
        this.ownerId = obj._id;
    }

    get parents(): Obj[] {
        return this.parentIds.map((id: string) => {
            return new Obj(this.app, id);
        });
    }

    /** Load the document from the relevant collection in the database
     *
     * @returns {Promise<void>|Promise} Promise resolved when document loaded, rejected on failure
     */
    load(): Promise<void> {
        return new Promise<void>((resolve, reject) => {
            this.collection.find({_id: this._id}).limit(1).toArray().then((docs: Object[]) => {
                if(_.isEmpty(docs)) return reject(new ObjNotFoundError());
                let doc = docs[0];
                this.setProps(doc);
                this.loaded = true;
                resolve();
            }).catch((err) => reject(err));
        });
    }

    /**
     * Saves the object to the database
     * @returns {Promise<void>|Promise}
     */
    save(): Promise<void> {
        return new Promise<void>((resolve, reject) => {
            // Validate first
            let validation = this.validate();
            if(!validation.success) return reject(new ValidationErrorLocal('an Obj validation error occurred', <Joi.ValidationError><any>validation.error)); // TODO return with validation data

            let obj = this.getProps();

            return this.collection.updateOne({_id: this._id}, obj, {upsert: true}).then(() => resolve());
        });
    }

    /**
     * Saves the object to the database and emits an event onto the SystemBus
     * @returns {Promise<void>|Promise}
     */
    update(): Promise<void> {
        return new Promise<void>((resolve, reject) => {
            this.save().then(() => {
                // Emit the new serialized obj onto the system bus
                this.app.systemBus.broadcast('obj', this.getProps());
                resolve();
            }).catch((err) => reject(err));
        });
    }

    /**
     * Removes (deletes) the object from the database and emits an event onto the SystemBus
     * @return {Promise<void>}
     */
    async remove(): Promise<void> {
        await this.collection.deleteOne({_id: this._id});
        this.app.systemBus.broadcast('obj-remove', this._id);
    }

    /**
     * Gets an array of Obj representing this object's children, sorted by xtime descending
     * @param limit The maximum amount of Objs to return
     * @returns {Promise<Obj[]>|Promise}
     */
    async getChildren(limit?: number): Promise<Obj[]> {
        return (await this.collection.find({parentIds: this._id})
            .limit(limit || 0)
            .sort({xtime: -1})
            .toArray())
            .map((doc: any) => {

            let obj = new Obj(this.app, doc['_id']);
            obj.setProps(doc);
            return obj;
        }) as any as Obj[];
    }

    /**
     * Recursive get all the children of this object
     * @param maxLevel Maximum number of levels to crawl.
     * @param limits
     * @param grabOwners Treat owners of objects as children
     * @param level Internal use only - current level
     * @returns {Promise<Obj[]>|Promise} Promised resolved with flat array of objects
     */
    async getChildrenTree(maxLevel: number, limits: number[] = [], grabOwners: boolean = false, level: number = 0): Promise<Obj[]> {
        if(level === 0) maxLevel--;
        if(maxLevel < 0) return []; // Resolve nothing if no levels are requested

        let children = await this.getChildren(limits[0]); // Pass topmost element in limits array to getChildren, if it doesn't exist then undefined will be passed, resulting in no limit.
        if(grabOwners) {
            if(!this.loaded) await this.load();
            if(this.ownerId && this.ownerId !== this._id) { // If we finally have an owner and it's not ourself (cyclical)
                let owner = this.owner;
                await owner.load();
                children.push(owner);
            }
        }
        if(level >= maxLevel) return children;

        // Run another pass of getChildrenRecursive, concat those children to our children, and return
        return _.uniqBy(_.flatten(await Promise.all(children.map((child) => {
            //
            return child.getChildrenTree(maxLevel, limits.slice(1), grabOwners, level + 1)
        }))).concat(children), '_id');
    }
}