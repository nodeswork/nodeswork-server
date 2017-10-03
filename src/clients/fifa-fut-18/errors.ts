import { NodesworkError } from '@nodeswork/utils';

export const ACCOUNT_IS_NOT_READY_ERROR = NodesworkError.internalServerError(
  'Account is not ready',
);

export const UNKNOWN_AUTH_RESPONSE_ERROR = NodesworkError.internalServerError(
  'Unknown Fifa FUT 18 auth response',
);

export const UNKNOWN_AUTH_PROMPT_RESPONSE_ERROR =
  NodesworkError.internalServerError(
    'Unknown Fifa FUT 18 auth prompt response',
  );

export const UNKNOWN_LOGIN_FORM_RESPONSE_ERROR =
  NodesworkError.internalServerError(
    'Unknown Fifa FUT 18 login form response',
  );

export const UNKNOWN_LOGIN_FORM_VERIFY_RESPONSE_ERROR =
  NodesworkError.internalServerError(
    'Unknown Fifa FUT 18 login form verify response title',
  );

export class RequireLoginVerificationError extends NodesworkError {

  constructor(public nextUrl: string) {
    super('Require Fifa FUT 18 Login Verification');
  }
}

export const UNKNOWN_USER_ACCOUNT_INFO_ERROR =
  NodesworkError.internalServerError('Unknown user account info');

export const INVALID_CREDENTIALS_ERROR =
  NodesworkError.internalServerError(
    'Invalid Fifa FUT 18 Login Credentials',
  );
