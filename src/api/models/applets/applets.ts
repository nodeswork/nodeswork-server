import * as mongoose     from 'mongoose';
import * as sbase        from '@nodeswork/sbase';

import { generateToken } from '../../../utils/tokens';

export const DATA_LEVELS = {
  DETAIL:  'DETAIL',
  TOKEN:   'TOKEN',
};

export const PERMISSIONS = {
  PRIVATE:  'PRIVATE',
  PUBLIC:   'PUBLIC',
  LIMIT:    'LIMIT',
};

export type AppletTypeT = typeof Applet & sbase.mongoose.NModelType;
export interface AppletType extends AppletTypeT {}

const AppletTokens = new mongoose.Schema({

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
});

const AppletConfig = new mongoose.Schema({

  na:           {
    type:       String,
    enum:       ['npm'],
    default:    'npm',
  },

  naVersion:    {
    type:       String,
    enum:       ['8.3.0'],
    default:    '8.3.0',
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
});

export class Applet extends sbase.mongoose.NModel {

  public static $CONFIG: sbase.mongoose.ModelConfig = {
    collection:        'applets',
    dataLevel:         {
      levels:          [ DATA_LEVELS.DETAIL, DATA_LEVELS.TOKEN ],
      default:         DATA_LEVELS.DETAIL,
    },
  };

  public static $SCHEMA: object = {

    owner:            {
      type:           mongoose.Schema.Types.ObjectId,
      ref:            'User',
      required:       true,
      index:          true,
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
      max:            [1400, 'Description should be at most 1400 charactors.'],
      dataLevel:      DATA_LEVELS.DETAIL,
    },

    tokens:           {
      type:           AppletTokens,
      default:        AppletTokens,
      api:            sbase.mongoose.AUTOGEN,
      dataLevel:      DATA_LEVELS.TOKEN,
    },

    permission:       {
      type:           String,
      enum:           Object.keys(PERMISSIONS),
      default:        PERMISSIONS.PRIVATE,
      dataLevel:      DATA_LEVELS.DETAIL,
    },

    verionedConfigs:  {
      type:           [ AppletConfig ],
      dataLevel:      DATA_LEVELS.DETAIL,
    },
  };
}
