import * as _            from 'underscore';
import * as mongoose     from 'mongoose';
import * as sbase        from '@nodeswork/sbase';

import { generateToken } from '../../../utils/tokens';

import compareVersion = require('compare-version');

const APPLET_DATA_LEVELS = {
  DETAIL:  'DETAIL',
  TOKEN:   'TOKEN',
};

const APPLET_PERMISSIONS = {
  PRIVATE:  'PRIVATE',
  PUBLIC:   'PUBLIC',
};

export type AppletType = typeof Applet & sbase.mongoose.NModelType;

export interface AppletTokens {
  devToken:   string;
  prodToken:  string;
}

export const AppletTokens = new mongoose.Schema({

  devToken:             {
    type:            String,
    required:        true,
    default:         generateToken,
  },

  prodToken:         {
    type:            String,
    required:        true,
    default:         generateToken,
  },
}, { _id: false });

@sbase.mongoose.Config({
  _id: false,
})
export class AppletWorkerConfig extends sbase.mongoose.Model {

  @sbase.mongoose.Field({
    type: String,
  })
  public name:         string;

  @sbase.mongoose.Field({
    type: String,
  })
  public schedule:     string;

  @sbase.mongoose.Field({
    type: String,
  })
  public handler:      string;

  @sbase.mongoose.Field({
    type: String,
  })
  public displayName:  string;

  @sbase.mongoose.Field({
    type: Boolean,
  })
  public default:      boolean;

  @sbase.mongoose.Field({
    type: Boolean,
  })
  public hide:         boolean;
}

export interface AppletAccountConfig {
  accountType: string;
  provider:    string;
  optional:    boolean;
  multiple:    boolean;
}

export class AppletImage extends sbase.mongoose.Model {

  @sbase.mongoose.Field({
    type:       String,
    enum:       ['npm'],
    default:    'npm',
    required:   true,
  })
  public naType:       string;

  @sbase.mongoose.Field({
    type:       String,
    enum:       ['8.3.0'],
    default:    '8.3.0',
    required:   true,
  })
  public naVersion:    string;

  @sbase.mongoose.Field({
    type:       String,
    required:   true,
  })
  public packageName:  string;

  @sbase.mongoose.Field({
    type:       String,
    required:   true,
  })
  public version:      string;
}

export class AppletConfig extends AppletImage {

  @sbase.mongoose.Field({
    type:           [
      AppletWorkerConfig.$mongooseOptions().mongooseSchema,
    ],
  })
  public workers:      AppletWorkerConfig[];

  @sbase.mongoose.Field({
    type: [{
      accountType: String,
      provider:    String,
      optional:    Boolean,
      multiple:    Boolean,
    }],
  })
  public accounts:     AppletAccountConfig[];
}

@sbase.mongoose.Config({
  collection:        'applets',
  dataLevel:         {
    levels:          [ APPLET_DATA_LEVELS.DETAIL, APPLET_DATA_LEVELS.TOKEN ],
    default:         APPLET_DATA_LEVELS.DETAIL,
  },
  toObject:          {
    virtuals:        true,
  },
  id: false,
})
export class Applet extends sbase.mongoose.NModel {

  public static DATA_LEVELS = APPLET_DATA_LEVELS;
  public static PERMISSIONS = APPLET_PERMISSIONS;

  @sbase.mongoose.Field({
    type:           mongoose.Schema.Types.ObjectId,
    ref:            'User',
    required:       true,
    index:          true,
    api:            sbase.mongoose.READONLY,
  })
  public owner:     mongoose.Schema.Types.ObjectId;

  @sbase.mongoose.Field({
    type:           String,
    required:       true,
    unique:         true,
  })
  public name:      string;

  @sbase.mongoose.Field({
    type:           String,
    default:        'http://www.nodeswork.com/favicon.ico',
  })
  public imageUrl:  string;

  @sbase.mongoose.Field({
    type:           String,
    max:            [ 1400, 'description should be at most 1400 charactors' ],
    level:          APPLET_DATA_LEVELS.DETAIL,
  })
  public description: string;

  @sbase.mongoose.Field({
    type:           AppletTokens,
    default:        AppletTokens,
    api:            sbase.mongoose.AUTOGEN,
    level:          APPLET_DATA_LEVELS.TOKEN,
  })
  public tokens:    AppletTokens;

  @sbase.mongoose.Field({
    type:           String,
    enum:           Object.keys(APPLET_PERMISSIONS),
    default:        APPLET_PERMISSIONS.PRIVATE,
    level:          APPLET_DATA_LEVELS.DETAIL,
  })
  public permission: string;

  @sbase.mongoose.Field({
    type:           [ AppletConfig.$mongooseOptions().mongooseSchema ],
    level:          APPLET_DATA_LEVELS.DETAIL,
    validate:       [ validateConfig, 'config is required' ],
    api:            sbase.mongoose.AUTOGEN,
  })
  public configHistories:  AppletConfig[];

  get config(): AppletConfig {
    return this.configHistories[this.configHistories.length - 1];
  }

  set config(value: AppletConfig) {
    if (value != null) {
      const index = _.findIndex(
        this.configHistories,
        (c) => compareVersion(c.version, value.version) === 0,
      );
      if (index === -1) {
        delete value._id;
        this.configHistories.push(value);
        this.configHistories.sort(
          (a, b) => compareVersion(a.version, b.version),
        );
      } else {
        this.configHistories[index] = value;
      }
    }
  }
}

function validateConfig(configs: AppletConfig[]) {
  return configs.length > 0;
}
