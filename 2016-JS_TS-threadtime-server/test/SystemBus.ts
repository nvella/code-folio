/// <reference path="../node_modules/@types/mocha/index.d.ts" />

import {expect} from "chai";
import * as amqplib from 'amqplib';

import { SystemBus } from '../src';

describe('SystemBus', () => {
    let bus: SystemBus;

    describe('constructor', () => {
        it('can set its instance variables without any AMQP service provided', () => {
            bus = new SystemBus();
            expect(bus.amqpConfig).to.equal(null);
            expect(bus.uid).to.be.a('string');
        });
    });

    describe('#start', () => {
        beforeEach(() => {
            bus = new SystemBus({
                addr: process.env.BUS_AMQP_ADDR || 'amqp://localhost',
                exchange: 'test'
            });
        });

        afterEach(() => bus.stop());

        it('can connect to the amqp', async () => {
            await bus.start();
            expect(bus.amqpConn).to.be.an('object');
        });

        it('can connect an amqp channel', async () => {
            await bus.start();
            expect(bus.amqpChan).to.be.an('object');
        });

        it('can start successfully', () => bus.start());
    });

    describe('#stop', () => {
        beforeEach(async () => {
            bus = new SystemBus({
                addr: process.env.BUS_AMQP_ADDR || 'amqp://localhost',
                exchange: 'test'
            });
            await bus.start();
        });

        it('can stop successfully', () => bus.stop());
    });

    describe('message passing', () => {
        let bus1: SystemBus;
        let bus2: SystemBus;

        beforeEach(async () => {
            bus1 = new SystemBus({
                addr: process.env.BUS_AMQP_ADDR || 'amqp://localhost',
                exchange: 'test'
            });
            bus2 = new SystemBus({
                addr: process.env.BUS_AMQP_ADDR || 'amqp://localhost',
                exchange: 'test'
            });

            await bus1.start();
            await bus2.start();
        });

        afterEach(async () => {
            await bus1.stop();
            await bus2.stop();
        });

        it('can receive a message sent from bus 1 to bus 2', (done) => {
            let msg = { foo: 'bar', baz: 2 };

            bus2.on('data', (recvMsg: any) => {
                expect(recvMsg).to.eql(msg);
                done();
            });

            bus1.broadcast('data', msg);
        });

        it('can receive a message sent from bus 2 to bus 1', (done) => {
            let msg = { foo: 'biz', baz: false };

            bus1.on('data', (recvMsg: any) => {
                expect(recvMsg).to.eql(msg);
                done();
            });

            bus2.broadcast('data', msg);
        });

        it('cannot receive it\'s own messages twice (eg over amqp)', (done) => {
            let msg = { foo: 'bar', baz: 3 };
            let counter = 0;

            bus1.on('data', (recvMsg: any) => {
                expect(recvMsg).to.eql(msg);
                counter++;
            });

            bus1.broadcast('data', msg);

            setTimeout(() => {
                expect(counter).to.equal(1);
                done();
            }, 100);
        });

        it('cannot receive messages from another amqp exchange', (done) => {
            let msg = { foo: 'bar', baz: 3 };

            let otherBus = new SystemBus({
                addr: process.env.BUS_AMQP_ADDR || 'amqp://localhost',
                exchange: 'a-diff-exchange'
            });

            bus1.on('data', (recvMsg: any) => {
                done(new Error('bus1 should not have received any data.'));
            });

            otherBus.broadcast('data', msg);

            setTimeout(() => {
                done();
            }, 100);
        });
    });
});