{ sendMail } = require '../../dist/mail/mailer'

describe 'mailer', ->

  describe 'sendMail', ->

    it 'sends mail successfully', ->

      object = await sendMail()
      console.log object
