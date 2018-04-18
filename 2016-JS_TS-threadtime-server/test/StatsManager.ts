/// <reference path="../node_modules/@types/mocha/index.d.ts" />

import {expect} from "chai";
import {StatsManager} from "../src/StatsManager";
import {InfluxDB} from "influx";

describe('StatsManager', () => {
    let statsManager: StatsManager;
    const uri = process.env.INFLUXDB_URI || 'http://localhost:8086/threadtime';

    describe('constructor', () => {
        it('can set its instance variables without any InfluxDB provided', () => {
            statsManager = new StatsManager('test');
            expect(statsManager.db).to.equal(null);
            expect(statsManager.batchIntervalMs).to.equal(10000);
        });

        it('can create an InfluxDB instance if provided with an influx db address', () => {
            statsManager = new StatsManager('test', 'http://localhost:8086');
            expect(statsManager.db).to.be.an.instanceof(InfluxDB);
        });
    });

    describe('#start', () => {
        it('can set an interval for handleBatchInterval', (done) => {
            statsManager = new StatsManager('test', uri, 1000);
            (statsManager as any).handleBatchInterval = () => {
                statsManager.stop();
                done();
            };
            statsManager.start();
        });
    });

    describe('#stop', () => {
        it('can stop the interval', (done) => {
            statsManager = new StatsManager('test', uri, 100);
            (statsManager as any).handleBatchInterval = () => {
                done(new Error('the batch interval should not have been triggered'));
            };
            statsManager.start().then(() => statsManager.stop());

            setTimeout(() => done(), 500);
        })
    });

    describe('#point', () => {
        it('does nothing if there is no db', () => {
            statsManager = new StatsManager('test');
            statsManager.point('test', {count: 0});
            expect(statsManager.pointsBatch).to.be.empty;
        });

        it('can add the point to the batch if there is a DB', () => {
            statsManager = new StatsManager('test', uri);
            statsManager.point('measurement-here', {count: 0});
            expect(statsManager.pointsBatch).to.not.be.empty;

            expect(statsManager.pointsBatch[0].measurement).to.equal('measurement-here');
            expect(statsManager.pointsBatch[0].tags).to.eql({'host': 'test'});
            expect(statsManager.pointsBatch[0].fields).to.eql({count: 0});
            expect(statsManager.pointsBatch[0].timestamp).to.be.an.instanceof(Date);
        });
    });

    describe('pointsBatch processing', () => {
        beforeEach(async () => {
            statsManager = new StatsManager('test', uri, 100);
            await statsManager.db.createDatabase(uri.split('/').splice(-1));
            await statsManager.start();
        });

        afterEach(async () => {
            await statsManager.stop();
            await statsManager.db.dropMeasurement('test');
        });

        it('can write out points to the db', (done) => {
            statsManager.point('test', {abc: '123'});
            let point = statsManager.pointsBatch[0];
            setTimeout(() => {
                statsManager.db.query('select * from test;').then((results) => {
                    expect(results).to.have.length(1);
                    done();
                }).catch((err) => done(err));
            }, 500);
        });

        it('can clear the pointsBatch', (done) => {
            statsManager.point('test', {abc: '123'});

            setTimeout(() => {
                expect(statsManager.pointsBatch).to.be.empty;
                done();
            }, 500);
        });
    });
});