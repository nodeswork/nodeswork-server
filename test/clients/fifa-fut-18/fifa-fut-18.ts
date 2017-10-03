import * as request   from 'request-promise';

import * as fifaFut18 from '../../../src/clients/fifa-fut-18';

describe('client > fifa-fut-18', () => {

  it('should load', () => {
    fifaFut18.should.be.ok();
  });

  describe('#login', () => {

    // it('failed when crendential is wrong', async () => {
      // const client  = new fifaFut18.FifaFut18Client({
        // email:     'wrong@gmail.com',
        // password:  'wrong pass',
        // secret:    '???',
        // platform:  'xone',
        // jar:       request.jar(),
      // });

      // try {
        // await client.ensureLogin();
        // false.should.be.ok();
      // } catch (e) {
        // e.should.be.equal(fifaFut18.errors.INVALID_CREDENTIALS_ERROR);
      // }
    // });

    // const jar     = request.jar();

    // it('pauses at login verification phrase', async () => {
      // const client  = new fifaFut18.FifaFut18Client({
        // email: 'zyz.4.zyz@gmail.com',
        // password: '',
        // secret: '???',
        // platform: 'xone',
        // jar,
      // });

      // try {
        // await client.ensureLogin();
        // false.should.be.ok();
      // } catch (e) {
        // e.should.be.equal(fifaFut18.errors.REQUIRE_LOGIN_VERIFICATION_ERROR);
      // }
    // });
  });
});
