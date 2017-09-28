import * as logger     from '@nodeswork/logger';

import * as models     from '../models';
import {
  DeviceSocket,
  deviceSocketManager,
}                      from './device-socket-manager';

const LOG = logger.getLogger();

export const deviceSocket = {
  namespace: '/device',
  middlewares: [ authorize ],
  onConnection,
};

async function onConnection(socket: DeviceSocket) {
  LOG.info('New device connection', { deviceId: socket.device._id });

  deviceSocketManager.register(socket);

  // TODO: Hack all devices as user device.
  const userApplets = await models.UserApplet.find({
    user: (socket.device as models.UserDevice).user,
  }, undefined, {
    populate: [
      {
        path: 'applet',
        options: {
          level: models.Applet.DATA_LEVELS.TOKEN,
        },
      },
    ],
  });

  // Asynchronously check device applets running status.
  socket.device.checkAppletRunningStatus(userApplets).catch((err) => {
    LOG.error('Checking device running status failed', err);
  });

  socket.on('disconnect', () => {
    LOG.info('Lost device connection', { deviceId: socket.device._id });
    deviceSocketManager.unregister(socket);
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

  const device = await models.Device.findOne({ token });

  if (device == null) {
    next(new Error('token is invalid'));
    setTimeout(() => { socket.disconnect(); }, 100);
    return;
  }

  socket.device = device;
  next();
}
