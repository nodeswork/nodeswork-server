import { Meta, NodesworkError } from "@nodeswork/utils";

/**
 * Base class for url parameter error.
 */
export class UrlParameterError extends NodesworkError {

  constructor(message: string, meta: Meta = {}, cause?: Error) {
    meta.responseCode = 422;
    super(message, meta, cause);
  }
}

export const EMAIL_ADDRESS_IS_ALREADY_VERIFIED = new UrlParameterError(
  "Email address is already verified",
);

export const UNRECOGNIZED_TOKEN_ERROR = new UrlParameterError(
  "Unrecognized token",
);
