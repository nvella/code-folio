// Type definitions for nanomsg, based off ZeroMQ Node's
// Project: https://github.com/JustinTulloss/zeromq.node
// Definitions by: Dave McKeown <http://github.com/davemckeown>
// Definitions: https://github.com/DefinitelyTyped/DefinitelyTyped

/// <reference types="node" />

declare module "nanomsg" {
    interface EventEmitter {
    }

    interface SocketTypes {
        pub: number;
        xpub: number;
        sub: number;
        xsub: number;
        req: number;
        xreq: number;
        rep: number;
        xrep: number;
        push: number;
        pull: number;
        dealer: number;
        router: number;
        pair: number;
    }

    interface SocketOptions {
        tcpnodelay?: boolean,
        linger?: number,
        sndbuf?: number,
        rcvbuf?: number,
        sndtimeo?: number,
        rcvtimeo?: number,
        reconn?: number,
        maxreconn?: number,
        sndprio?: number,
        rcvprio?: number,
        ipv6?: boolean,
        rcvmaxsize?: number,
        chan?: string[],
        wsopt?: string
    }

    interface Socket extends EventEmitter {
        /**
         * Bind.
         *
         * @param addr Socket address
         */
        bind(addr: string): void;

        /**
         * Shutdown (unbind) the socket
         * @param addr Socket address
         */
        shutdown(addr: string): void;

        /**
         * Connect to `addr`.
         *
         * @param addr Connection address
         */
        connect(addr: string): Socket;

        /**
         * Send the given `msg`.
         *
         * @param msg The message
         */
        send(msg: string): Socket;

        /**
         * Send the given `msg`.
         *
         * @param msg {Buffer} The message
         */
        send(msg: Buffer): Socket;

        /**
         * Close the socket.
         *
         */
        close(): Socket;

        /**
         * Socket event
         * @param eventName {string}
         * @param callback {Function}
         */
        on(eventName: string, callback: (data: string) => void): void;
    }

    export function socket(type: string, options?: SocketOptions): Socket;
}