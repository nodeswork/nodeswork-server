import * as nodemailer from 'nodemailer'

let transporter = nodemailer.createTransport(
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
