import * as mongoose from 'mongoose';

function Email(path: string, options: any) {
  mongoose.SchemaTypes.String.call(this, path, options, 'Email');
  function validateEmail(val: string) {
    return /^[a-zA-Z0-9._+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6}$/.test(val);
  }
  this.validate(validateEmail, 'Invalid email address', 'invalid-email');
}

Email.prototype.__proto__ = mongoose.SchemaTypes.String.prototype;

Email.prototype.cast = (val: any) => {
  if (val.constructor !== String) {
    throw new (mongoose.SchemaType as any).CastError(
      'Email', `${val} is not a string`,
    );
  }
  return val;
};

(mongoose.SchemaTypes as any).Email = Email;
