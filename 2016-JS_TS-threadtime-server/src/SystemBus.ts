import * as shortid from 'shortid';
import * as amqplib from 'amqplib';
import { EventEmitter } from 'events';

export interface ISystemBusAMQPConfig {
    addr: string;
    exchange: string;
}

/**
 * Handles communications among a distributed or single-node Threadtime Server system,
 * optionally utilising AMQP.
 */
export class SystemBus extends EventEmitter {
    private started: boolean;

    uid: string;

    amqpConfig: ISystemBusAMQPConfig;
    amqpConn: amqplib.Connection = null;
    amqpChan: amqplib.Channel = null;

    constructor(amqpConfig: ISystemBusAMQPConfig = null) {
        super();

        this.started = false;
        this.uid = shortid.generate();
        this.amqpConfig = amqpConfig;
    }

    /**
     * Starts a SystemBus, optionally interlinking with an AMQP system.
     * @returns {Promise<void>|Promise} Promise resolved when Bus is started
     */
    async start(): Promise<void> {
        if(this.amqpConfig) {
            // Attempt to connect to the AMQP server
            let sleep = (ms: number) => {
                return new Promise<void>((resolve) => {
                    setTimeout(resolve, ms);
                });
            };

            for(let i = 0; i < 4; i++) {
                try {
                    this.amqpConn = await amqplib.connect(this.amqpConfig.addr);
                    break; // Break the loop on successful connect
                } catch(e) {
                    if(i === 4 - 1) throw e; // Throw the error up on last try
                }

                await sleep(1000);
            }

            // Connect channel and assert our exchange
            this.amqpChan = await this.amqpConn.createChannel();
            await this.amqpChan.assertExchange(this.amqpConfig.exchange, 'fanout', {durable: false});

            // Create a queue to receive messages on and bind it to the exchange
            let q = await this.amqpChan.assertQueue('', {exclusive: true});
            await this.amqpChan.bindQueue(q.queue, this.amqpConfig.exchange, '');

            // Hook incoming messages messages
            await this.amqpChan.consume(q.queue, this.handleAmqpMsg);
        }
    }

    /**
     * Stops a SystemBus and disconnects from any AMQP system
     */
    async stop(): Promise<void> {
        // Close AMQP channels (if they exist)
        if(this.amqpChan) await this.amqpChan.close();

        // Close AMQP connection (if it exists)
        if(this.amqpConn) await this.amqpConn.close();
    }

    /**
     * Broadcasts a message onto the bus
     * @param event The event identifier
     * @param message The message to broadcast
     */
    broadcast(event: string, message: any) {
        if(this.amqpChan) {
            // Push the message onto the AMQP queue
            this.amqpChan.publish(this.amqpConfig.exchange, '', new Buffer(JSON.stringify({
                u: this.uid,
                e: event,
                m: message
            })));
        }

        // Emit it onto the local event emitter
        this.emit(event, message);
    }

    private handleAmqpMsg = (msg: amqplib.Message) => {
        if(msg === null) return; // Return on null message

        // Acknowledge the message
        this.amqpChan.ack(msg);

        // JSON parse the content
        let content = JSON.parse(msg.content.toString());
        if(content.u === this.uid) return; // Ignore messages that originate from ourself.

        // Emit it onto our local event emitter
        this.emit(content.e, content.m);
    };
}