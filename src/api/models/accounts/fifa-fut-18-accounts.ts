import * as mongoose      from 'mongoose';
import * as _             from 'underscore';
import * as tough         from 'tough-cookie';
import * as request       from 'request-promise';

import * as sbase         from '@nodeswork/sbase';
import { NodesworkError } from '@nodeswork/utils';

import {
  CookieAccount,
  CookieAccountType,
}                         from './cookie-accounts';
import { Account }        from './accounts';
import {
  FifaFut18Client,
  Fifa18ClientMetadata,
  STATES,
}                         from '../../../clients/fifa-fut-18';

export type FifaFut18AccountType = typeof FifaFut18Account & CookieAccountType;

@sbase.mongoose.Config({})
export class FifaFut18Account extends CookieAccount {

  @sbase.mongoose.Field({
    type:      String,
    required:  true,
    api:       sbase.mongoose.READONLY,
  })
  public email: string;

  @sbase.mongoose.Field({
    type:      mongoose.Schema.Types.Mixed,
    level:     Account.DATA_LEVELS.CREDENTIAL,
    api:       sbase.mongoose.AUTOGEN,
    default:   {},
  })
  public clientMetadata: Fifa18ClientMetadata;

  public reset() {
    this.cookieString   = '';
    this.clientMetadata = {};
  }

  private getFifa18Client(): FifaFut18Client {
    const jar: any = request.jar();

    if (this.cookieString) {
      jar._jar = tough.CookieJar.fromJSON(this.cookieString);
    }

    const clientOptions = {
      email: this.email,
      jar,
      metadata: this.clientMetadata,
    };
    return new FifaFut18Client(clientOptions);
  }

  private dumpFifa18Client(client: FifaFut18Client) {
    const w               = client.options.jar as any;
    const cookie          = w._jar as tough.CookieJar;
    this.cookieString     = JSON.stringify(cookie.toJSON());
    this.clientMetadata   = client.metadata;
  }

  public async verify(options: VerifyStepOptions): Promise<object> {
    if (isStep1(options)) {
      this.reset();
    }

    const fifaClient = this.getFifa18Client();

    if (isStep1(options)) {
      await fifaClient.login(options.password);
    } else if (isStep2(options)) {
      await fifaClient.verifySecurityCode(options.code);
    } else if (isStep4(options)) {
      await fifaClient.verifySecret(options.secret);
    }

    this.dumpFifa18Client(fifaClient);
    this.verified = fifaClient.metadata.state === STATES.READY;
    await this.save();

    return {
      status:    'ok',
      metadata:  fifaClient.metadata,
    };
  }
}

export interface VerifyOptions {
  step: number;
}

export type VerifyStepOptions = VerifyStep1Options | VerifyStep2Options |
  VerifyStep4Options;

export interface VerifyStep1Options extends VerifyOptions {
  password: string;
}

export interface VerifyStep2Options extends VerifyOptions {
  code: string;
}

export interface VerifyStep4Options extends VerifyOptions {
  secret: string;
}

function isStep1(options: VerifyStepOptions): options is VerifyStep1Options {
  return options.step === 1;
}

function isStep2(options: VerifyStepOptions): options is VerifyStep2Options {
  return options.step === 2;
}

function isStep4(options: VerifyStepOptions): options is VerifyStep4Options {
  return options.step === 4;
}
