import * as sio from 'socket.io';
import * as bcrypt from 'bcrypt';
import * as async from 'async';
import * as _ from 'lodash';
import { EventEmitter } from 'events';

import {
    Message,
    HandshakeMessage,
    AuthMessage,
    PermanentDisconnectMessage,
    DisconnectMachineReason,
    MessageType,
    NetHandler,
    StatusMessage,
    ObjMessage,
    ObjType,
    IUserData, HandshakeResponseMessage, ObjCacheStateMessage, RmObjMessage, IObj
} from '@threadtime/threadtime-common';
import { App, UserObj, Obj, SubscriptionDispatch } from './';
import {ObjNotFoundError, ValidationError} from "./Errors";
import {ObjProcessor} from "./ObjProcessors/ObjProcessor";
import {PostObjProcessor} from "./ObjProcessors/PostObjProcessor";

export class Client extends EventEmitter {
    private app: App; 
    private socket: SocketIO.Socket;

    netHandler: NetHandler;
    clientVersion: string | null;
    connected: boolean = false;

    authenticated: boolean = false;
    userObj: UserObj = null;
    subscriptionDispatch: SubscriptionDispatch;

    objProcessors: {[type: number]: ObjProcessor};

    /**
     * Construct a Client
     * @param app The App from which the Client originates
     * @param socket The SocketIO socket
     */
    constructor(app: App, socket: SocketIO.Socket) {
        super();
        this.app = app;
        this.socket = socket;
        this.netHandler = new NetHandler(socket);
        this.subscriptionDispatch = new SubscriptionDispatch(this.app, this);

        let genericProcessor = new ObjProcessor(this.app, this);
        this.objProcessors = {
            [ObjType.Generic]:   genericProcessor,
            [ObjType.Board]:     genericProcessor,
            [ObjType.Post]:      new PostObjProcessor(this.app, this),
            [ObjType.User]:      genericProcessor,
            [ObjType.UserPrefs]: genericProcessor
        } as any;
    }

    /**
     * Start the client
     */
    start(): void {
        this.log('Starting connection...');
        // Emit 'client-disconnect' event on disconnect
        this.socket.on('disconnect', () => this.stop());

        // Set-up handshake handler
        this.netHandler.onMessage(MessageType.Handshake, (msg: Message) => this.handleHandshake(msg));
        // Set up after-handshake handlers
        this.on('handshake', () => {
            this.netHandler.onMessage(MessageType.Auth, (msg: Message) => this.handleAuth(msg).catch((err) => {
                this.log(`#handleAuth error: ${err}`);

                // Respond with failed status
                let statusMsg = new StatusMessage(this.netHandler);
                statusMsg.success = false;
                statusMsg.respondTo(msg);
            }));

            this.netHandler.onMessage(MessageType.UnAuth, (msg: Message) => this.handleUnAuth(msg).catch((err) => {
                this.log(`#handleUnAuth error: ${err}`);

                // Respond with failed status
                let statusMsg = new StatusMessage(this.netHandler);
                statusMsg.success = false;
                statusMsg.respondTo(msg);
            }));

            this.netHandler.onMessage(MessageType.Obj, (msg: Message) => {
                this.handleObj(msg).catch((err) => {
                    this.log(`#handleObj error: ${err}`);

                    // Respond with failed status
                    let statusMsg = new StatusMessage(this.netHandler);
                    statusMsg.success = false;
                    statusMsg.respondTo(msg);
                });
            });

            this.netHandler.onMessage(MessageType.ObjCacheState, (msg: Message) => this.handleObjCacheState(msg).catch((err) => {
                this.log(`#handleObjCacheState error: ${err}`);
            }));

            this.netHandler.onMessage(MessageType.RmObj, (msg: Message) => {
                this.handleRmObj(msg).catch((err) => {
                    this.log(`#handleRmObj error: ${err}`);

                    // Respond with failed status
                    let statusMsg = new StatusMessage(this.netHandler);
                    statusMsg.success = false;
                    statusMsg.respondTo(msg);
                });
            });
        });

        // Bind the SubscriptionDispatch
        this.subscriptionDispatch.bind();

        this.connected = true;
    }

    /**
     * Stop the client
     * @returns {Promise<boolean>|Promise} Resolved when the client has stopped
     */
    async stop(): Promise<boolean> {
        if(!this.connected) return false; // Don't 'disconnect' if already DC'd

        this.log('Stopping connection...');
        this.connected = false;
        if(this.socket.connected) this.socket.disconnect(true);
        this.app.emit('client-disconnect', this);
        this.log('Connection stopped');
        return true;
    }

    /**
     * Log in the context of this Client
     * @param str The string to log
     */
    log(str: string): void {
        this.app.log.info(`[${this.userObj ? this.userObj._id + '(' + this.userObj.name + ')@' : ''}${this.socket.client.conn.remoteAddress}] ${str}`);
    }

    private handleHandshake(msg: Message): void {
        let handshakeMsg = new HandshakeMessage(this.netHandler).encapsulate(msg);
        this.log(`Handshake v=${handshakeMsg.version}`);

        if(handshakeMsg.version !== App.VERSION) {
            this.log('Versions incompatible, kicking');
            let dcMsg = new PermanentDisconnectMessage(this.netHandler);
            dcMsg.machineReason = DisconnectMachineReason.VersionMismatch;
            dcMsg.humanReason = `Client-Server version mismatch (server ${App.VERSION}`;
            this.netHandler.send(dcMsg);
            this.stop();
            return;
        }

        // Set client version in instance
        this.clientVersion = handshakeMsg.version;

        // Otherwise, reply back with handshake
        let resp = new HandshakeResponseMessage(this.netHandler);
        resp.version = App.VERSION;
        resp.serverName = this.app.serverName;
        resp.replyTo = handshakeMsg.id;
        this.netHandler.send(resp);

        // Emit handshake
        this.emit('handshake');
    }

    private async handleAuth(msg: Message): Promise<void> {
        let authMsg = new AuthMessage(this.netHandler).encapsulate(msg);
        this.log(`Authenticating user=${authMsg.username}`);

        this.log('  fetching userdata...');
        let userdata: IUserData = await this.app.collections['userdata'].findOne({username: authMsg.username});

        // Check if the user exists
        if(userdata === null) throw new Error('User does not exist');

        // Check the token
        if(userdata.tokens.filter((tokenData) => tokenData.token === authMsg.token).length === 0) throw new Error('Auth token does not match');

        // Fetch the UserObj
        this.userObj = (new UserObj(this.app)).encapsulate(await this.app.obj(userdata.objId));

        this.log(`User ${authMsg.username} authenticated successfully.`);

        // Set flags and usernames
        this.authenticated = true;

        // Emit auth-success
        this.emit('auth-success');

        // Send a success status messsage
        let statusMsg = new StatusMessage(this.netHandler);
        statusMsg.success = true;
        statusMsg.respondTo(authMsg);

        // Insert stat for authenticatedCount
        this.app.statsManager.point('authCount', {count: this.app.clients.filter((client) => client.authenticated).length});
    }

    private async handleUnAuth(msg: Message): Promise<void> {
        // Reject if not authenticated
        if (!this.authenticated) throw new Error('User not authenticated');
        // Don't care about the message as it's not requried

        this.log(`Unauthenticating...`);

        this.authenticated = false;
        this.userObj = null;

        this.emit('unauth');

        // Send a success status messsage
        let statusMsg = new StatusMessage(this.netHandler);
        statusMsg.success = true;
        statusMsg.respondTo(msg);

        // Insert stat for authenticatedCount
        this.app.statsManager.point('authCount', {count: this.app.clients.filter((client) => client.authenticated).length});
    }

    private async handleObj(msg: Message) {
        // NOTE only handles one Obj at a time
        let objMsg = (new ObjMessage(this.netHandler)).encapsulate(msg);

        // Reject if not authenticated
        if (!this.authenticated) throw new Error('User not authenticated');

        // If no objs were provided, err
        if (_.isEmpty(objMsg.objs)) throw new Error();

        let iobj = objMsg.objs[0];

        // Attempt to load the obj
        let obj: Obj;
        try {
            // Do update stuff
            // Check if Obj exists, err if not
            obj = await this.app.obj(objMsg.objs[0]._id);

            // Check permissions
            let permSpec = this.authenticated ? this.userObj.permsOver(obj) : obj.perms.all;
            if(!permSpec.modify) throw new Error('User does not have permission to modify this obj');

            let newRev = obj.rev + 1;
            obj.setProps(iobj);
            obj.rev = newRev; // Increase revision

            // Run the relevant ObjProcessor in modify mode
            this.objProcessors[obj.type].doOnModify(obj);
        } catch (err) {
            if (err.name !== 'ObjNotFoundError') throw err; // Error was not an ObjNotFoundError, throw it up

            // Lookup the parents, confirming that they exist and that we have permission to add to them
            let collectedParents = [];
            for(let parentId of iobj.parentIds || []) {
                let parent = await this.app.obj(parentId);
                let permSpec = this.userObj.permsOver(parent);
                let childPerms = permSpec.children[parseInt(iobj._id || '0')] || permSpec.children[ObjType.Generic];

                if(!childPerms.add) throw new Error(`User cannot add obj as child to ${parent._id}`);

                // Collect the parents to update their xtime values
                collectedParents.push(parent);
            }

            // Update the xtime values of the parents
            for(let parent of collectedParents) {
                parent.xtime = Math.floor(+ new Date() / 1000);
                parent.rev++; // Bump the revision number
                try {
                    await parent.update();
                } catch(e) {
                    this.log(`Error in updating xtime value of parent ${parent._id}`);
                }
            }

            // Create the obj
            obj = new Obj(this.app, iobj._id);
            obj.setProps(iobj); // Load in the obj props
            obj.owner = this.userObj;
            obj.regenerateId(); // Do not trust the client-provided id

            // Run the relevant ObjProcessor in create mode
            this.objProcessors[obj.type].doOnCreate(obj);
        }

        // Update the Obj
        try {
            await obj.update();
        } catch(err) {
            // ERR
            this.log(`Error in obj post update: ${err}`);
            if (err instanceof ValidationError) this.log(`Validation error: ${(<ValidationError>err).joiError.message}`);
            throw err;
        }

        // Send the new objs back to the client
        let newObjMsg = new ObjMessage(this.netHandler);
        newObjMsg.objs = [obj.getProps()];
        newObjMsg.respondTo(msg);
    }

    private async handleObjCacheState(msg: Message) {
        let objCacheStateMsg = new ObjCacheStateMessage(this.netHandler).encapsulate(msg);

        // Get the IDs of Objs currently in the DB
        let cacheObjIds = _.keys(objCacheStateMsg.objCacheState);
        let realObjIds = (await this.app.collections['objects'].find({_id: {$in: cacheObjIds}}).toArray()).map((obj: IObj) => obj._id);

        // For each of the cache entries
        let revokeObjIds = _.difference(cacheObjIds, realObjIds);
        if(!_.isEmpty(revokeObjIds)) {
            // Send an RmObjs message
            let rmObjMsg = new RmObjMessage(this.netHandler);
            rmObjMsg.objIds = revokeObjIds;
            this.netHandler.send(rmObjMsg);
        }
    }

    private async handleRmObj(msg: Message) {
        let rmObjMsg = new RmObjMessage(this.netHandler).encapsulate(msg);

        let objs = [];
        // Collect all the Objs
        for(let id of rmObjMsg.objIds) {
            let obj = await this.app.obj(id);

            // Check that the user has permission to modify the Obj
            let permSpec = this.authenticated ? this.userObj.permsOver(obj) : obj.perms.all;
            if(!permSpec.modify) throw new Error('User does not have permission to modify this obj');

            objs.push(obj);
        }

        // Delet all the Objs
        for(let obj of objs) await obj.remove();

        // Send the list of deleted Obj IDs back to the client
        let reply = new RmObjMessage(this.netHandler);
        reply.objIds = rmObjMsg.objIds;
        reply.respondTo(rmObjMsg);
    }
}