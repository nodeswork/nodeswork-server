import * as crypto        from 'crypto';
import * as mongoose      from 'mongoose';
import * as _             from 'underscore';
import * as request       from 'request-promise';

import * as sbase         from '@nodeswork/sbase';
import { NodesworkError } from '@nodeswork/utils';

import {
  Account,
  AccountType,
  AccountOperateOptions,
}                         from './accounts';
import * as errors        from '../../errors';
import * as models        from '../../models';

export type WEXAccountType = typeof WEXAccount & AccountType;

@sbase.mongoose.Config({})
export class WEXAccount extends Account {

  @sbase.mongoose.Field({
    type:      String,
    level:     Account.DATA_LEVELS.DETAIL,
    required:  true,
  })
  public key: string;

  @sbase.mongoose.Field({
    type:      String,
    level:     Account.DATA_LEVELS.DETAIL,
    required:  true,
  })
  public secret: string;

  @sbase.mongoose.Field({
    type:      Number,
    level:     Account.DATA_LEVELS.DETAIL,
    default:   0,
  })
  public nonce: number;

  public async verify() {
    const info = await this.operate({
      method:  'GET',
      ref:     'getInfo',
    }, null);

    if (info.success) {
      this.verified = true;
      await this.save();
      return {
        status: 'ok',
      };
    } else {
      this.verified = false;
      await this.save();
      return {
        status: 'error',
        error: info.error,
      };
    }
  }

  public async operate(
    options: AccountOperateOptions,
    userApplet: models.UserApplet,
  ): Promise<any> {
    const params = options.body || {};
    params.method = options.ref;
    params.nonce = ++this.nonce;

    const body = _.chain(Object.keys(params))
      .sort()
      .map((name) => `${name}=${params[name]}`)
      .join('&')
      .value();

    const sign = crypto
      .createHmac('sha512', this.secret)
      .update(body)
      .digest('hex');

    try {
      const res = await request.post({
        uri: 'https://wex.nz/tapi',
        headers: {
          Key: this.key,
          Sign: sign,
        },
        form: body,
        json: true,
      });
      if (res.success === 0 && (
        res.error === 'invalid api key' || res.error === 'invalid sign'
      )) {
        this.verified = false;
      }
      return res;
    } finally {
      await this.save();
    }
  }
}
