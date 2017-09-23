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

export type AppletTypeT = typeof Applet & sbase.mongoose.NModelType;
export interface AppletType extends AppletTypeT {}

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

export interface AppletWorkerConfig {
  name:      string;
  schedule:  string;
}

export interface AppletAccountConfig {
  accountType: string;
  provider:    string;
  optional:    boolean;
  multiple:    boolean;
}

export interface AppletConfig {
  _id:          mongoose.Schema.Types.ObjectId;
  naType:       string;
  naVersion:    string;
  packageName:  string;
  version:      string;
  workers:      AppletWorkerConfig[];
  accounts:     AppletAccountConfig[];
}

export class AppletImage extends sbase.mongoose.Model {

  public naType:       string;
  public naVersion:    string;
  public packageName:  string;
  public version:      string;

  public static $SCHEMA: object = {

    naType:       {
      type:       String,
      enum:       ['npm'],
      default:    'npm',
      required:   true,
    },

    naVersion:    {
      type:       String,
      enum:       ['8.3.0'],
      default:    '8.3.0',
      required:   true,
    },

    packageName:  {
      type:       String,
      required:   true,
    },

    version:      {
      type:       String,
      required:   true,
    },
  };
}

export const AppletConfig = new mongoose.Schema({

  naType:       {
    type:       String,
    enum:       ['npm'],
    default:    'npm',
    required:   true,
  },

  naVersion:    {
    type:       String,
    enum:       ['8.3.0'],
    default:    '8.3.0',
    required:   true,
  },

  packageName:  {
    type:       String,
    required:   true,
  },

  version:      {
    type:       String,
    required:   true,
  },

  workers:      [{
    name:       String,
    schedule:   String,
  }],

  accounts:     [{
    accountType: String,
    provider:    String,
    optional:    Boolean,
    multiple:    Boolean,
  }],
});

export class Applet extends sbase.mongoose.NModel {

  public static DATA_LEVELS = APPLET_DATA_LEVELS;
  public static PERMISSIONS = APPLET_PERMISSIONS;

  public static $CONFIG: mongoose.SchemaOptions = {
    collection:        'applets',
    dataLevel:         {
      levels:          [ APPLET_DATA_LEVELS.DETAIL, APPLET_DATA_LEVELS.TOKEN ],
      default:         APPLET_DATA_LEVELS.DETAIL,
    },
    toObject:          {
      virtuals:        true,
    },
    id: false,
  };

  public owner:            mongoose.Schema.Types.ObjectId;
  public name:             string;
  public imageUrl:         string;
  public description:      string;
  public tokens:           AppletTokens;
  public permission:       string;
  public configHistories:  AppletConfig[];

  public static $SCHEMA: object = {

    owner:            {
      type:           mongoose.Schema.Types.ObjectId,
      ref:            'User',
      required:       true,
      index:          true,
      api:            sbase.mongoose.READONLY,
    },

    name:             {
      type:           String,
      required:       true,
      unique:         true,
    },

    imageUrl:         {
      type:           String,
      default:        'http://www.nodeswork.com/favicon.ico',
    },

    description:      {
      type:           String,
      max:            [ 1400, 'description should be at most 1400 charactors' ],
      level:          APPLET_DATA_LEVELS.DETAIL,
    },

    tokens:           {
      type:           AppletTokens,
      default:        AppletTokens,
      api:            sbase.mongoose.AUTOGEN,
      level:          APPLET_DATA_LEVELS.TOKEN,
    },

    permission:       {
      type:           String,
      enum:           Object.keys(APPLET_PERMISSIONS),
      default:        APPLET_PERMISSIONS.PRIVATE,
      level:          APPLET_DATA_LEVELS.DETAIL,
    },

    configHistories:  {
      type:           [ AppletConfig ],
      level:          APPLET_DATA_LEVELS.DETAIL,
      validate:       [ validateConfig, 'config is required' ],
      api:            sbase.mongoose.AUTOGEN,
    },
  };

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
