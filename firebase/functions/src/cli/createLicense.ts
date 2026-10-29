/**
 * Issue a license from the command line until the admin portal can
 * (Sprint 9). Uses the same logic and checks as the `createLicense` function.
 *
 *   GOOGLE_APPLICATION_CREDENTIALS=service-account.json \
 *     node functions/lib/cli/createLicense.js --company <companyId> \
 *       --admin <developerAdminUid> [--months 12] [--devices 2]
 *
 * Prints the activation code once; it is not stored anywhere.
 */
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { createLicense } from '../licenses.js';

function arg(name: string, fallback?: string): string {
  const i = process.argv.indexOf(`--${name}`);
  const v = i >= 0 ? process.argv[i + 1] : fallback;
  if (v === undefined) {
    console.error(`Missing --${name}`);
    process.exit(1);
  }
  return v;
}

const months = Number(arg('months', '12'));
const now = new Date();
const until = new Date(now);
until.setMonth(until.getMonth() + months);

initializeApp();
createLicense(getFirestore(), arg('admin'), {
  companyId: arg('company'),
  validFrom: now.getTime(),
  validUntil: until.getTime(),
  maxDevices: Number(arg('devices', '2')),
})
  .then(({ licenseId, activationCode }) => {
    console.log(`License ${licenseId} valid until ${until.toISOString().slice(0, 10)}`);
    console.log(`Activation code (shown once): ${activationCode}`);
  })
  .catch((e: Error) => {
    console.error(e.message);
    process.exit(1);
  });
