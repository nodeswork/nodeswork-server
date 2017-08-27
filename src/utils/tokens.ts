const randToken = require('rand-token');

export function generateToken(size: number = 16): string {
  return randToken.generate(size);
}
