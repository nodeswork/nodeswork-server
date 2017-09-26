import { Meta, NodesworkError } from '@nodeswork/utils';

/**
 * Base class for url parameter error.
 */
export class UrlParameterError extends NodesworkError {

  constructor(message: string, meta: Meta = {}, cause?: Error) {
    if (meta.responseCode == null) {
      meta.responseCode = 422;
    }
    super(message, meta, cause);
  }
}

export const EMAIL_ADDRESS_IS_ALREADY_VERIFIED = new UrlParameterError(
  'Email address is already verified',
);

export const UNRECOGNIZED_TOKEN_ERROR = new UrlParameterError(
  'Unrecognized token',
);

export const PASSWORD_TOO_SHORT_ERROR = new UrlParameterError(
  'invalid value',
  {
    errors: {
      password: {
        path: 'password',
        kind: 'password should contain at least 6 characters',
      },
    },
  },
);

export const USER_NOT_EXISTS_ERROR = new UrlParameterError(
  'user does not exist',
);

export const USER_NOT_ACTIVE_ERROR = new UrlParameterError(
  'user is not active',
);

export const INVALID_PASSWORD_ERROR = new UrlParameterError(
  'password is wrong',
  { responseCode: 401 },
);

export const REQUIRE_LOGIN_ERROR = new UrlParameterError(
  'require login',
  { responseCode: 401 },
);

export const REQUIRE_DEVICE_TOKEN_ERROR = new UrlParameterError(
  'require device token',
  { responseCode: 401 },
);

export const INVALID_DEVICE_TOKEN_ERROR = new UrlParameterError(
  'invalid device token',
  { responseCode: 401 },
);

export const INVALID_WORKER = new UrlParameterError(
  'invalid worker',
);

export const DEVICE_OFFLINE = new UrlParameterError(
  'device is offline',
);
