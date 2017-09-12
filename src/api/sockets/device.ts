import * as logger             from '@nodeswork/logger';
import { NAMSocketRpcClient }  from '@nodeswork/nam/dist/client';

import { Device, defs }        from '../models';

const LOG = logger.getLogger();

export const deviceSocket = {
  namespace: '/device',
  middlewares: [ authorize ],
  onConnection,
};

export const deviceSocketMap: {
  [name: string]: NAMSocketRpcClient;
} = {};

export interface DeviceSocket extends SocketIO.Socket {
  device: defs.Device;
}

function onConnection(socket: DeviceSocket) {
  LOG.info('New device connection', { deviceId: socket.device._id });

  const client = new NAMSocketRpcClient(socket);
  deviceSocketMap[socket.device._id.toString()] = client;

  socket.on('disconnect', () => {
    LOG.info('Lost device connection', { deviceId: socket.device._id });
    delete deviceSocketMap[socket.device._id.toString()];
  });
}

async function authorize(
  socket: DeviceSocket, next: (error?: Error) => void,
) {
  const token = socket.handshake.query.token;
  LOG.info('Authorize device socket', { token });

  if (token == null) {
    return next(new Error('token is missing'));
  }

  const device = await Device.findOne({ token });

  if (device == null) {
    next(new Error('token is invalid'));
    setTimeout(() => { socket.disconnect(); }, 100);
    return;
  }

  socket.device = device;
  next();
}
