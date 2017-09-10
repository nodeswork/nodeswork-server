import * as SocketIO    from 'socket.io';

import * as logger      from '@nodeswork/logger';

import { deviceSocket } from './device';

const LOG = logger.getLogger();

export function setupSockets(srv: any) {
  LOG.info('setting SocketIO');

  const io = SocketIO(srv);

  io
    .on('connection', (socket) => {
      LOG.info('New socket connection with', socket.handshake.query);
      socket.on('disconnect', () => {
        LOG.info('Disconnect', socket.handshake.query.token);
      });
    })
  ;

  io
    .of(deviceSocket.namespace)
    .use(deviceSocket.middlewares[0])
    .on('connection', deviceSocket.onConnection)
  ;

  return io;
}

export { deviceSocketMap } from './device';
