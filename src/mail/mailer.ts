import * as nodemailer from 'nodemailer'

import { config } from '../config'

let transporter = nodemailer.createTransport(
  `smtps://${config.secrets.mailerUsername}:${config.secrets.mailerSMPTTransporter}@smtp.gmail.com`
);

export function sendMail(
  to: string
): Promise<nodemailer.SentMessageInfo> {
  return transporter.sendMail({
    from: config.mailer.sender,
    to,
    subject: 'TEST',
    text: 'TEST',
    html: '<b>TEST<b>',
  });
}
