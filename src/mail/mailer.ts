import * as nodemailer from 'nodemailer'

import { config } from '../config'

let transporter = nodemailer.createTransport(
  `smtps://andy%40nodeswork.com:${config.secrets.mailerSMPTTransporter}@smtp.gmail.com`
);

export function sendMail(): Promise<nodemailer.SentMessageInfo> {
  return transporter.sendMail({
    from: '"Andy Zhao" <andy@nodeswork.com>',
    to: '"Andy Zhao" <andy@nodeswork.com>',
    subject: 'TEST',
    text: 'TEST',
    html: '<b>TEST<b>',
  });
}
