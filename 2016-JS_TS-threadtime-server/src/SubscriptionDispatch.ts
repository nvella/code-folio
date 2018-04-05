import * as _ from 'lodash';

import { App, Obj } from './';
import {Client} from "./Client";
import {
    MessageType, Message, AddSubscriptionMessage, RmSubscriptionMessage,
    ISubscription, ObjMessage, IObj, RmObjMessage, NetHandler, IObjCacheState, ObjCacheStateMessage, StatusMessage,
    ObjType, ISubObjMap
} from "@threadtime/threadtime-common";
import {ObjLookupByNameMessage} from "@threadtime/threadtime-common/dist/src/Messages/ObjLookupByNameMessage";

export class SubscriptionDispatch {
    private app: App;
    private client: Client;
    private netHandler: NetHandler;

    subscriptions: {[key: string]: ISubscription};
    objCache: {[subscriptionUid: string]: SubscriptionDispatchObjCacheEntry};
    clientCacheState: IObjCacheState;

    static MAX_DISTANCE = 8;

    /**
     * Construct a SubscriptionDispatch
     * @param app Threadtime Server App instance
     * @param client The Client to which this SubscriptionManager will be bound
     */
    constructor(app: App, client: Client) {
        this.app = app;
        this.client = client;
        this.netHandler = client.netHandler;

        this.subscriptions = {};
        this.objCache = {};
        this.clientCacheState = {};
    }

    /**
     * Binds this SubscriptionDispatch to the NetHandler and the App
     */
    bind(): void {
        // Set-up AddSubscription handler
        this.netHandler.onMessage(MessageType.AddSubscription, (msg: Message) =>
            this.addSubscription((new AddSubscriptionMessage(this.netHandler)).encapsulate(msg).subscription));

        // Set-up RmSubscription handler
        this.netHandler.onMessage(MessageType.RmSubscription, (msg: Message) =>
            this.rmSubscription((new RmSubscriptionMessage(this.netHandler)).encapsulate(msg).subscriptionIds));

        // Set-up ObjCacheState handler
        this.netHandler.onMessage(MessageType.ObjCacheState, (msg: Message) => {
            let objCacheStateMsg = new ObjCacheStateMessage(this.netHandler).encapsulate(msg);
            this.clientCacheState = objCacheStateMsg.objCacheState;
        });

        // Set-up obj lookup by name handler
        this.netHandler.onMessage(MessageType.ObjLookupByName, (msg: Message) => {
            let objLookupMsg = new ObjLookupByNameMessage(this.netHandler).encapsulate(msg);
            this.objLookupByName(objLookupMsg.objName, objLookupMsg.objType).then((obj: Obj) => {
                if(obj === null) {
                    // Nothing found, reply status success false
                    let statusMsg = new StatusMessage(this.netHandler);
                    statusMsg.success = false;
                    statusMsg.respondTo(msg);
                } else {
                    // Send the Objs
                    let objMsg = new ObjMessage(this.netHandler);
                    objMsg.objs = [obj.getProps()];
                    objMsg.respondTo(msg);
                }
            });
        });

        // Set-up obj update/create handler
        this.app.systemBus.on('obj', (obj: IObj) => this.objUpdate(obj));

        // Set-up obj removal handler
        this.app.systemBus.on('obj-remove', (objId: string) => this.objRemove(objId));
    }

    /**
     * Add a subscription, allowing the client to receive updates on those objects
     * @param subscription The subscription to add
     */
    async addSubscription(subscription: ISubscription): Promise<void> {
        // Add the subscription to the list of subscriptions
        this.subscriptions[subscription.uid] = subscription;

        // Push initial update
        let objs = await this.app.collectObjs(subscription.objectIds, subscription.depth, subscription.limits, subscription.grabOwners);

        // Cache ObjIds affected
        let cacheEntry: SubscriptionDispatchObjCacheEntry = {};
        _.forEach(objs, (obj: Obj) => {
            cacheEntry[obj._id] = obj.parentIds;
            if(subscription.grabOwners) {
                cacheEntry[obj._id] = cacheEntry[obj._id].concat(
                    // Add any owner-parents
                    objs.filter((searchObj) => searchObj.ownerId === obj._id && searchObj._id !== obj._id).map((obj) => obj._id)
                )
            }

        });
        cacheEntry = this.cleanCacheEntry(cacheEntry);

        this.objCache[subscription.uid] = cacheEntry;

        // Generate the Sub Obj Map
        let subObjMap: ISubObjMap = {};
        // For each of the Objs, get the Sub IDs
        for(let obj of objs) {
            let subIds = this.findSubIdsForObj(obj._id);
            for(let subId of subIds) {
                // Push it
                if(!_.has(subObjMap, subId)) subObjMap[subId] = [];
                subObjMap[subId].push(obj._id);
            }
        }

        // Push these objs to the client
        this.pushObjs(objs.map((obj) => obj.getProps()), subObjMap);
    }

    /**
     * Remove one or more subscriptions
     * @param subscriptionIds The IDs of the Subscriptions to remove
     */
    rmSubscription(subscriptionIds: string[]) {
        // Remove the subscription from the list of subscriptions
        for(let id of subscriptionIds) {
            if(this.subscriptions[id]) delete this.subscriptions[id];
            if(this.objCache[id]) delete this.objCache[id];
        }
    }

    /**
     * Process an Obj update on the provided Obj
     * @param obj The new or existing Obj
     */
    async objUpdate(obj: IObj): Promise<void> {
        // If this obj id is present of any of the subscriptions, it's an update
        let subIds = this.findSubIdsForObj(obj._id);
        if(!_.isEmpty(subIds)) {
            // Create a SubObjMap
            let subObjMap: ISubObjMap = {};
            for(let subId of subIds) subObjMap[subId] = [obj._id];

            // Push it to the client
            this.pushObjs([obj], subObjMap);

            // Update it's entry in the cache (parentIds possibly may have changed)
            for(let subId of subIds) {
                // this.objCache[subId][obj._id] = obj.parentIds;
                this.objCache[subId] = this.cleanCacheEntry(this.objCache[subId]);
            }

            return;
        }

        let subObjMap: ISubObjMap = {};
        let objsToPush = [obj];

        // Obj is new. For each of this obj's parent ids:
        for(let parentId of obj.parentIds) {
            // Find all the subIds for this parent
            // If nothing is found, the function simply falls through
            let subIds = this.findSubIdsForObj(parentId);

            // For each of the subIds affected by this parent
            for(let subId of subIds) {
                let subscription = this.subscriptions[subId];
                let cache = this.objCache[subId];

                // For each of the subscribed Obj IDs, calculate the distance between the parent ID and it
                let parentDistance = this.distance(cache, parentId, subscription.objectIds);
                if(parentDistance === undefined) return; // There is no path to these objects available.

                if(parentDistance + 1 <= subscription.depth) {
                    // This object is affected by the subscription.

                    // Add it to the cache
                    this.objCache[subId][obj._id] = obj.parentIds;

                    // Handle grabOwners - send owner as well
                    // TODO Crawl the owner hierarchy somehow
                    if(subscription.grabOwners &&
                        parentDistance + 2 <= subscription.depth &&
                        obj.ownerId
                    ) {
                        // Grab the owner if it exists
                        try {
                            let owner = await this.app.obj(obj.ownerId);
                            objsToPush.push(owner.getProps());
                            this.objCache[subId][owner._id] = (this.objCache[subId][owner._id] || []).concat(obj._id);
                        } catch(e) {}
                    }

                    // Clean the cache
                    this.objCache[subId] = this.cleanCacheEntry(this.objCache[subId]);

                    // Push the subscription onto the affected subs list
                    subObjMap[subId] = [obj._id];
                }
            };
        }

        // If the Obj is affected by an existing subscription, push it along with all the relevant subscription IDs
        if(_.keys(subObjMap).length > 0) this.pushObjs(objsToPush, subObjMap);
    }

    /**
     * Process an Obj removal
     * @param objId The id of the Obj being removed
     */
    objRemove(objId: string) {
        let subIds = this.findSubIdsForObj(objId);
        if(!_.isEmpty(subIds)) {
            // Send rmObj message
            this.rmObjsFromClient([objId]);

            // For each of the affected subscriptions, remove the obj from the cache
            _.forEach(subIds, (subId: string) => this.rmObjInCacheEntry(subId, objId));
        }
    }

    objLookupByName(name: string, type: ObjType): Promise<Obj> {
        return new Promise<Obj>((resolve, reject) => {
            this.app.collections['objects'].findOne({
                name: name,
                _id: {$regex: `^${type}.*$`}
            }).then((doc: IObj) => {
                if(doc === null || doc === undefined) {
                    // Obj not found
                    resolve(null);
                } else {
                    // Create a new Obj and send it
                    let obj = new Obj(this.app, doc._id);
                    obj.setProps(doc);

                    resolve(obj);
                }
            }).catch((err) => reject(err));
        });
    }

    private pushObjs(iobjs: IObj[], subObjMap: ISubObjMap = {}) {
        // Only send the objs when we have a newer version
        iobjs = iobjs.filter((iobj) => iobj.rev > (iobj._id in this.clientCacheState ? this.clientCacheState[iobj._id] : -1));
        // Filter out objs we don't have permission to send
        iobjs = iobjs.filter((iobj) => {
            let permSpec = this.client.authenticated ? this.client.userObj.permsOver(iobj) : iobj.perms.all;
            return permSpec.view;
        });

        // Push these objects to the child
        let objMsg = new ObjMessage(this.netHandler);
        objMsg.objs = iobjs;
        objMsg.subObjMap = subObjMap;

        // Send the message
        this.netHandler.send(objMsg);

        // Update the client cache state for each of the Objs sent
        for(let iobj of iobjs) this.clientCacheState[iobj._id] = iobj.rev;
    }

    private rmObjsFromClient(objIds: string[]) {
        let rmObjMsg = new RmObjMessage(this.netHandler);
        rmObjMsg.objIds = objIds;

        // Send the message
        this.netHandler.send(rmObjMsg);
    }

    private findSubIdsForObj(objId: string): string[] {
        let caches: string[] = [];

        _.forEach(this.objCache, (cache: SubscriptionDispatchObjCacheEntry, subId: string) => {
            if(cache[objId] !== undefined) caches.push(subId);
        });

        return caches;
    }

    private distance(cacheEntry: SubscriptionDispatchObjCacheEntry, objId: string, endObjIds: string[], curDepth: number = 0, map: {[id: string]: number} = {}): number {
        // Recursive algorithm that passes values in reverse
        if(_.includes(endObjIds, objId)) return 0; // The end of the object graph was reached, return 0

        // If we've reached the max depth, return zero
        if(curDepth > SubscriptionDispatch.MAX_DISTANCE) return 0;

        // Get the distances of each of the parents
        let distances: number[] = [];
        _.forEach(cacheEntry[objId], (parentId: string) => {
            if(!_.has(map, objId) || curDepth < map[objId]) {
                // Map paths to prevent us from following the same path twice at the highest depth
                map[objId] = curDepth;

                let result = this.distance(cacheEntry, parentId, endObjIds, curDepth + 1, map);

                // If a distance was returned, push it +1 onto the distances array
                if(typeof(result) === 'number') distances.push(result + 1);
            }
        });

        // Return the minimum value (shortest distance)
        return _.min(distances);
    }

    private rmObjInCacheEntry(subId: string, objId: string) {
        // WARNING - This function can be destructive on cyclic references.
        delete this.objCache[subId][objId];
        _.forEach(this.objCache[subId], (parentIds: string[], id: string) => {
            if(_.includes(parentIds, objId)) {
                _.pull(this.objCache[subId][id], objId);
                if(_.isEmpty(this.objCache[subId][id])) this.rmObjInCacheEntry(subId, id);
            }
        });
    }

    private cleanCacheEntry(cacheEntry: SubscriptionDispatchObjCacheEntry) {
        // Clean up the cache by deleting non-resolvable parentIds (ties up loose ends at the top of the subscription, lvl = 0)
        let cacheClean = _.cloneDeep(cacheEntry);
        _.forEach(cacheEntry, (parentIds: string[], id: string) => {
            cacheClean[id] = (_.filter as any)(parentIds, (parentId: string) => cacheEntry[parentId]);
        });
        return cacheClean;
    }
}

export interface SubscriptionDispatchObjCacheEntry {
    [id: string]: string[]
}