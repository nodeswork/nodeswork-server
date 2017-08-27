{ sendMail } = require '../../dist/mail/mailer'

describe 'mailer', ->

  describe 'sendMail', ->

    it 'sends mail successfully', ->

      to = '"Andy Zhau" <andy+test+server+unittest@nodeswork.com>'
      object = await sendMail('email-verification', to)
      object.messageId.should.be.ok()
