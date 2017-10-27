import * as crypto        from 'crypto';
import * as mongoose      from 'mongoose';
import * as qs            from 'qs';
import * as _             from 'underscore';
import * as request       from 'request-promise';

import * as sbase         from '@nodeswork/sbase';
import {
  NodesworkError,
  HTTP_DEPENDENCY_CASTER,
}                         from '@nodeswork/utils';

import {
  Account,
  AccountType,
  AccountOperateOptions,
}                         from './accounts';
import * as errors        from '../../errors';
import * as models        from '../../models';

export type KrakenAccountType = typeof KrakenAccount & AccountType;

@sbase.mongoose.Config({})
export class KrakenAccount extends Account {

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

  public async verify() {
    this.verified = false;

    const info = await this.operate({
      method:  'GET',
      ref:     'Balance',
    }, null);

    this.verified = true;
    await this.save();
    return this;
  }

  public async operate(
    options: AccountOperateOptions,
    userApplet: models.UserApplet,
  ): Promise<any> {
    const path     = `/0/private/${options.ref}`;
    const params   = options.body || {};
    params.nonce   = Date.now() * 1001;
    const body     = qs.stringify(params);

    const signature = getSignature(path, body, this.secret, params.nonce);

    const headers = {
      'API-Key':     this.key,
      'API-Sign':    signature,
      'User-Agent':  'Nodeswork API Client',
    };

    try {
      const res = JSON.parse(await request.post({
        uri:      `https://api.kraken.com${path}`,
        headers,
        body,
      }));
      if (res.error && res.error.length) {
        switch (res.error[0]) {
          case 'EAPI:Invalid key':
            this.verified = false;
            throw errors.wex.INVALID_API_KEY;
          default:
            throw NodesworkError.failedDependency(
              'unknown Kraken remote error', {
                result: res,
              },
            );
        }
      }
      return res;
    } catch (e) {
      throw NodesworkError.cast(e, {}, [HTTP_DEPENDENCY_CASTER]);
    } finally {
      await this.save();
    }
  }
}

function getSignature(
  path: string, message: string, secret: string, nonce: number,
): string {
  const hash     = crypto
    .createHash('sha256')
    .update(nonce + message)
    .digest('binary' as any);
  return crypto
    .createHmac('sha512', new Buffer(secret, 'base64'))
    .update(path + hash, 'binary' as any)
    .digest('base64');
}
