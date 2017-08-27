import * as mongoose from 'mongoose'

import * as tokens from './tokens'
import * as users from './users/users'

export let Token = tokens.Token.$register<tokens.Token, tokens.TokenType>();
export let User = users.User.$register<users.User, users.UserType>();
