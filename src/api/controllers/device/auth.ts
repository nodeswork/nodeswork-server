import * as Router       from 'koa-router';

import * as errors       from '../../errors';
import { Device }        from '../../models';
import { DeviceContext } from '../def';

export const DEVICE_HEADER_TOKEN_KEY = 'device-token';

export async function requireDevice(ctx: DeviceContext, next: () => void) {
  const token = ctx.request.headers[DEVICE_HEADER_TOKEN_KEY];
  if (token == null) {
    throw errors.REQUIRE_DEVICE_TOKEN_ERROR;
  }

  const device = await Device.findOne({ token });
  if (device == null) {
    throw errors.INVALID_DEVICE_TOKEN_ERROR;
  }

  ctx.device = device;

  await next();
}
