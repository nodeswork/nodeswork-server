import * as path from 'path'
import * as _ from 'underscore'
import { EmailTemplate } from 'email-templates'
import * as nodemailer from 'nodemailer'

import { config } from '../config'

let transporter = nodemailer.createTransport(
  `smtps://${config.secrets.mailerUsername}:${config.secrets.mailerSMPTTransporter}@smtp.gmail.com`
);

export async function sendMail(
  template:  string,
  to:        string,
  data:      object = {}
): Promise<nodemailer.SentMessageInfo> {

  let emailTemplate = cashedEmailTemplate(template);

  let result = await emailTemplate.render(data);

  return transporter.sendMail({
    from: config.mailer.sender,
    to,
    subject: result.subject,
    text: result.text,
    html: result.html,
  });
}


function getEmailTemplate(template: string): EmailTemplate {
  return new EmailTemplate(path.join(__dirname, 'templates', template));
}

interface IGetEmailTemplate {
  (template: string): EmailTemplate
}

let cashedEmailTemplate: IGetEmailTemplate = (
  _.memoize(getEmailTemplate) as any as IGetEmailTemplate
);
