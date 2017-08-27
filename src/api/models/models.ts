import * as mongoose from 'mongoose'

import * as tokens from './tokens'

export let Token = tokens.Token.$register<tokens.Token, tokens.TokenType>();
