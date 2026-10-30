import type { Api } from './lib/http.js'
import { registerAdminRoutes } from './modules/admin/adminRoutes.js'
import { registerAuthRoutes } from './modules/auth/authRoutes.js'
import { registerCompanyRoutes } from './modules/companies/companyRoutes.js'
import { registerInvoiceNumberRoutes } from './modules/invoice-numbers/invoiceNumberRoutes.js'
import { registerDeviceRoutes } from './modules/licenses/deviceRoutes.js'
import { registerMemberRoutes } from './modules/members/memberRoutes.js'
import { registerReplacementRoutes } from './modules/replacements/replacementRoutes.js'
import { registerSyncRoutes } from './modules/sync/syncRoutes.js'

/** Every module's routes, mounted under `/api/v1`. */
export function registerRoutes(api: Api) {
  registerAuthRoutes(api)
  registerCompanyRoutes(api)
  registerMemberRoutes(api)
  registerDeviceRoutes(api)
  registerReplacementRoutes(api)
  registerInvoiceNumberRoutes(api)
  registerSyncRoutes(api)
  registerAdminRoutes(api)
}
