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
    this.verified = false;

    const info = await this.operate({
      method:  'GET',
      ref:     'getInfo',
    }, null);

    this.verified = true;
    await this.save();
    return this;
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

      if (!res.success) {
        switch (res.error) {
          case 'invalid api key':
            this.verified = false;
            throw errors.wex.INVALID_API_KEY;
          case 'invalid sign':
            this.verified = false;
            throw errors.wex.INVALID_SIGNATURE;
          default:
            throw NodesworkError.failedDependency(
              'unknown WEX remote error', {
                result: res,
              },
            );
        }
      }
      return res;
    } finally {
      await this.save();
    }
  }
}
