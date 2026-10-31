-- Mobile sessions never expire (they end on sign-out, password reset,
-- account disable or reuse detection).
ALTER TABLE "refresh_tokens" ALTER COLUMN "expires_at" DROP NOT NULL;

-- Sessions that are still live keep going indefinitely.
UPDATE "refresh_tokens"
SET "expires_at" = NULL
WHERE "client" = 'mobile' AND "revoked_at" IS NULL AND "expires_at" > now();

-- Activation codes work once. Codes issued before this change are unused
-- until their next successful activation.
ALTER TABLE "licenses" ADD COLUMN "activation_code_used_at" TIMESTAMPTZ(3),
ADD COLUMN "activation_code_used_by" TEXT,
ADD COLUMN "activation_code_device_id" TEXT;
