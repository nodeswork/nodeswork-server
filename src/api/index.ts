import { router } from './controllers';

const sockets = require('./sockets');

export const models = require('./models');
export const attachIO = sockets.attachIO;

export {
  router,
};
