import type { AppContext } from '../../context.js'

/**
 * Emails a newly issued activation code to the company owner. Returns the
 * address it went to, or null when it was not sent (no SMTP configured, or
 * the mail server refused) — the admin then passes the code on themselves.
 */
export async function emailActivationCode(ctx: AppContext, companyId: string, code: string, opts: { approved?: boolean } = {}) {
  // Without SMTP the message would only be logged, and codes must never reach the logs.
  if (!ctx.mailer.delivers) return null
  const company = await ctx.db.company.findUnique({ where: { id: companyId }, include: { owner: { select: { email: true } } } })
  if (!company) return null
  const to = company.owner.email
  try {
    await ctx.mailer.send({
      to,
      subject: opts.approved ? `${company.name} is approved — your JCB Works activation code` : `New JCB Works activation code for ${company.name}`,
      text: [
        `Hello ${company.contactPerson},`,
        '',
        opts.approved ? `${company.name} has been approved for JCB Works.` : `A new activation code has been issued for ${company.name}.`,
        '',
        `Activation code: ${code}`,
        '',
        `1. Open the JCB Works app and sign in${opts.approved ? ` with ${to}` : ''}.`,
        '2. Enter the code when asked to activate the phone.',
        '',
        'The code works once, on one phone. For another phone, ask JCB Works support for a new code.',
        'Keep it private.',
      ].join('\n'),
    })
    return to
  } catch (err) {
    ctx.logger.error({ err, companyId }, 'Activation code email failed')
    return null
  }
}
