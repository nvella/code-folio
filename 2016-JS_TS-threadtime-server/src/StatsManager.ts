import {InfluxDB, IPoint} from 'influx';
import * as _ from 'lodash';

export class StatsManager {
    db: InfluxDB = null;
    batchInterval: any = null;

    pointsBatch: IPoint[] = [];

    private dbName: string;

    constructor(public host: string, influxDbUri?: string, public batchIntervalMs: number = 10000) {
        if(influxDbUri) {
            this.db = new InfluxDB(influxDbUri);
            this.dbName = influxDbUri.split('/').splice(-1)[0];
        }
    }

    async start() {
        if(!this.batchInterval && this.db) this.batchInterval = setInterval(this.handleBatchInterval, this.batchIntervalMs);
        if(this.db) {
            let databases = await this.db.getDatabaseNames();
            if(!_.includes(databases, this.dbName)) await this.db.createDatabase(this.dbName);
        }
    }

    async stop() {
        if(this.batchInterval) clearInterval(this.batchInterval);
        if(this.pointsBatch.length > 0) this.handleBatchInterval();
    }

    point(measurement: string, fields: any) {
        if(this.db) this.pointsBatch.push({
            measurement,
            tags: {'host': this.host},
            fields,
            timestamp: new Date()
        });
    }

    private handleBatchInterval = () => {
        if(this.pointsBatch.length > 0) {
            this.db.writePoints(this.pointsBatch).catch((err) => {
                console.error(`Error writing to InfluxDB: ${err}`);
            });
            this.pointsBatch = [];
        }
    };
}