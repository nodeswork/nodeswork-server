import { EmailTemplate } from "email-templates";
import * as nodemailer from "nodemailer";
import * as path from "path";
import * as _ from "underscore";

import { config } from "../config";

const transporter = nodemailer.createTransport(
  `smtps://${config.secrets.mailerUsername}:${config.secrets.mailerSMPTTransporter}@smtp.gmail.com`,
);

export async function sendMail(
  template:  string,
  to:        string,
  data:      object = {},
): Promise<nodemailer.SentMessageInfo> {

  const emailTemplate = cashedEmailTemplate(template);

  const result = await emailTemplate.render(data);

  return transporter.sendMail({
    from: config.mailer.sender,
    to,
    subject: result.subject,
    text: result.text,
    html: result.html,
  });
}

function getEmailTemplate(template: string): EmailTemplate {
  return new EmailTemplate(path.join(__dirname, "templates", template));
}

type IGetEmailTemplate = (template: string) => EmailTemplate;

const cashedEmailTemplate: IGetEmailTemplate = (
  _.memoize(getEmailTemplate) as any as IGetEmailTemplate
);
