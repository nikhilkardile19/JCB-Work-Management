import nodemailer from 'nodemailer'
import type { Logger } from 'pino'
import type { Config } from '../config/env.js'

export interface MailMessage {
  to: string
  subject: string
  text: string
}

export interface Mailer {
  /** False when messages only reach the log: secrets must not be sent through it. */
  readonly delivers: boolean
  send(message: MailMessage): Promise<void>
}

/** Development fallback: writes the message (including links) to the log. */
export class LogMailer implements Mailer {
  readonly delivers = false

  constructor(private readonly logger: Logger) {}

  async send(message: MailMessage) {
    this.logger.warn({ mail: message }, 'SMTP is not configured; email written to the log instead')
  }
}

/** Tests read sent messages from here. */
export class MemoryMailer implements Mailer {
  readonly delivers = true
  readonly sent: MailMessage[] = []

  async send(message: MailMessage) {
    this.sent.push(message)
  }
}

export function createMailer(config: Config, logger: Logger): Mailer {
  if (!config.SMTP_HOST) return new LogMailer(logger)
  const transport = nodemailer.createTransport({
    host: config.SMTP_HOST,
    port: config.SMTP_PORT,
    secure: config.SMTP_SECURE,
    auth: config.SMTP_USER ? { user: config.SMTP_USER, pass: config.SMTP_PASSWORD } : undefined,
  })
  return {
    delivers: true,
    async send({ to, subject, text }) {
      await transport.sendMail({ from: config.MAIL_FROM, to, subject, text })
    },
  }
}
