import * as sio from 'socket.io';
import * as http from 'http';
import * as winston from 'winston';
import * as async from 'async';
import * as shortid from 'shortid';
import * as os from 'os';
import * as _ from 'lodash';

import { MongoClient, Db as MongoDb, Collection as MongoCollection, MongoCallback } from 'mongodb';
import { EventEmitter } from 'events';

import { Obj, Client, SystemBus } from './';
import {ISystemBusAMQPConfig} from "./SystemBus";
import {StatsManager} from "./StatsManager";

export interface IAppConfig {
    port?: number;
    dbUri?: string;
    influxDbUri: string;
    serverName?: string;
    systemBusAmqp?: ISystemBusAMQPConfig;
}

export class App extends EventEmitter {
    static VERSION = '0.0.1';
    static COLLECTIONS = ['objects', 'userdata'];

    static DEFAULT_CONFIG: IAppConfig = {
        port: process.env.PORT ? parseInt(process.env.PORT) : 3000,
        dbUri: process.env.DB_URI || 'mongodb://localhost/threadtime',
        influxDbUri: process.env.INFLUXDB_URI || 'http://localhost:8086/threadtime',
        serverName: process.env.SERVER_NAME,
        systemBusAmqp: process.env.BUS_AMQP_ADDR ? {
            addr: process.env.BUS_AMQP_ADDR,
            exchange: process.env.BUS_AMQP_EXCHANGE
        } : null
    };

    public port: number;
    public clients: Client[];
    public log: winston.LoggerInstance;

    public dbUri: string;
    public db: MongoDb;
    public collections: {[key: string]: MongoCollection};

    public statsManager: StatsManager;

    public serverName: string;
    public systemBus: SystemBus;

    private http: http.Server;
    private io: SocketIO.Server;

    /**
     * Construct a Server
     * @param config An IAppConfig loaded with the server's configuration options
     */
    constructor(config: IAppConfig = App.DEFAULT_CONFIG) {
        super();

        this.port = config.port;
        this.dbUri = config.dbUri;
        this.http = http.createServer();

        this.io = sio(this.http, {
            pingInterval: 5000,
            pingTimeout: 10000,
            wsEngine: 'uws'
        } as any);

        this.clients = [];
        this.collections = {};

        // Set up server name
        this.serverName = config.serverName || os.hostname();

        // Set up system bus
        this.systemBus = new SystemBus(config.systemBusAmqp);

        // Set up stats manager
        this.statsManager = new StatsManager(this.serverName, config.influxDbUri);

        // Set up log
        this.log = new winston.Logger({ transports: [
            new winston.transports.Console({'timestamp': true}) 
        ]});

        // Set up connection handler
        this.io.on('connection', (socket) => {
            // Create new client
            let client = new Client(this, socket);
            // Add it to the clients list
            this.clients.push(client);
            // Push the new client count stat
            this.statsManager.point('clientCount', {count: this.clients.length});
            // Start the client
            client.start();
        });

        // Set up client-disconnect handler
        this.on('client-disconnect', (client: Client) => {
            // Pull the client from the clients array
            _.pull(this.clients, client);
            // Push the new client count stat
            this.statsManager.point('clientCount', {count: this.clients.length});
        });
    }

    /**
     * Starts the server
     * @returns {Promise<void>|Promise} Resolved when the server has started
     */
    async start(): Promise<void> {
        this.log.info(`Threadtime Server version ${App.VERSION} starting...`);

        this.db = await MongoClient.connect(this.dbUri);
        this.log.info('Database connected.');

        this.log.info('Connecting collections...');
        for(let col of App.COLLECTIONS) {
            this.log.info(`    ${col}...`);
            this.collections[col] = this.db.collection(col);
        }

        this.log.info('Connecting system bus...');
        await this.systemBus.start();

        this.log.info('Starting stats manager...');
        await this.statsManager.start();

        this.http.listen(this.port);
        this.log.info(`Now listening on ${this.port}`);
    }

    /**
     * Stop the server
     * @returns {Promise<void>|Promise} Resolved when the server has stopped
     */
    async stop(): Promise<void> {
        this.io.close(); // Stop the socket IO instance
        if(this.http.listening) await (new Promise<void>((resolve) => this.http.close(resolve)));

        this.log.info('Disconnecting system bus...');
        await this.systemBus.stop();

        this.log.info('Closing db...');
        await this.db.close(true);

        this.log.info('Stopping StatsManager...');
        await this.statsManager.stop();

        this.log.info('Server stopped.');
    }

    /**
     * Resolve a Obj
     * @param id Obj ID
     * @returns {Promise<Obj>|Promise} Resolved with a loaded Obj when the object has been resolved
     */
    obj(id: string): Promise<Obj> {
        return new Promise<Obj>((resolve, reject) => {
            let obj = new Obj(this, id);
            obj.load().then(() => resolve(obj)).catch((err) => reject(err));
        });
    }

    /**
     * Collect multiple Objs and optionally their children to a specified number of levels
     * @param ids IDs of Objs to collect
     * @param levels Amount of children levels that should be collected on the Objs. 0 = just the objects mentioned
     * @param limits Specification for which limits should be applied at which depths for each ID (element 0 in array is limit applied for first level of children for each ID). Refer to Obj#getChildrenTree for more information.
     * @param grabOwners Treat Obj owners as children and grab them too
     * @returns {Promise<Obj[]>|Promise}
     */
    async collectObjs(ids: string[], levels: number, limits: number[] = [], grabOwners: boolean = false): Promise<Obj[]> {
        // for every id, run this.obj(id), with result then get child tree with provided levels and concat to results array, resolve with results array
        let objs: Obj[] = [];

        for(let id of ids) {
            let obj = await this.obj(id);
            objs.push(obj);
            objs = objs.concat(await obj.getChildrenTree(levels, limits, grabOwners));
        }

        return objs;
    }
}