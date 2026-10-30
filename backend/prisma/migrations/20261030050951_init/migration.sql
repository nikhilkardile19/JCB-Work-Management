-- CreateEnum
CREATE TYPE "UserStatus" AS ENUM ('active', 'disabled');

-- CreateEnum
CREATE TYPE "AdminRole" AS ENUM ('super', 'support');

-- CreateEnum
CREATE TYPE "SessionClient" AS ENUM ('mobile', 'portal');

-- CreateEnum
CREATE TYPE "CompanyStatus" AS ENUM ('pending', 'active', 'suspended');

-- CreateEnum
CREATE TYPE "CompanyRole" AS ENUM ('owner', 'admin', 'manager', 'operator', 'accounts');

-- CreateEnum
CREATE TYPE "MemberStatus" AS ENUM ('active', 'disabled');

-- CreateEnum
CREATE TYPE "LicenseStatus" AS ENUM ('pending', 'active', 'suspended', 'expired', 'revoked');

-- CreateEnum
CREATE TYPE "DeviceStatus" AS ENUM ('active', 'revoked');

-- CreateEnum
CREATE TYPE "ReplacementStatus" AS ENUM ('pending', 'approved', 'rejected');

-- CreateEnum
CREATE TYPE "WorkLogStatus" AS ENUM ('draft', 'submitted', 'approved', 'rejected', 'invoiced', 'cancelled');

-- CreateEnum
CREATE TYPE "InvoiceStatus" AS ENUM ('draft', 'finalized', 'cancelled');

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password_hash" TEXT,
    "status" "UserStatus" NOT NULL DEFAULT 'active',
    "token_version" INTEGER NOT NULL DEFAULT 0,
    "password_changed_at" TIMESTAMPTZ(3),
    "last_login_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "developer_admins" (
    "user_id" TEXT NOT NULL,
    "role" "AdminRole" NOT NULL DEFAULT 'support',
    "permissions" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "developer_admins_pkey" PRIMARY KEY ("user_id")
);

-- CreateTable
CREATE TABLE "refresh_tokens" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "family_id" TEXT NOT NULL,
    "token_hash" TEXT NOT NULL,
    "client" "SessionClient" NOT NULL,
    "expires_at" TIMESTAMPTZ(3) NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "rotated_at" TIMESTAMPTZ(3),
    "replaced_by_id" TEXT,
    "revoked_at" TIMESTAMPTZ(3),
    "revoke_reason" TEXT,
    "user_agent" TEXT,
    "ip" TEXT,

    CONSTRAINT "refresh_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "password_reset_tokens" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "token_hash" TEXT NOT NULL,
    "expires_at" TIMESTAMPTZ(3) NOT NULL,
    "used_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "password_reset_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "companies" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "contact_person" TEXT NOT NULL,
    "phone" TEXT NOT NULL,
    "email" TEXT,
    "address" TEXT NOT NULL,
    "gstin" TEXT,
    "invoice_prefix" TEXT NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "status" "CompanyStatus" NOT NULL DEFAULT 'pending',
    "owner_user_id" TEXT NOT NULL,
    "created_by" TEXT,
    "updated_by" TEXT,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "companies_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "company_members" (
    "company_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "role" "CompanyRole" NOT NULL,
    "status" "MemberStatus" NOT NULL DEFAULT 'active',
    "invited_by" TEXT,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "company_members_pkey" PRIMARY KEY ("company_id","user_id")
);

-- CreateTable
CREATE TABLE "licenses" (
    "id" TEXT NOT NULL,
    "company_id" TEXT NOT NULL,
    "status" "LicenseStatus" NOT NULL,
    "valid_from" TIMESTAMPTZ(3) NOT NULL,
    "valid_until" TIMESTAMPTZ(3) NOT NULL,
    "max_devices" INTEGER NOT NULL,
    "activation_code_hash" TEXT NOT NULL,
    "last_validated_at" TIMESTAMPTZ(3),
    "created_by" TEXT,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "licenses_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "devices" (
    "company_id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "license_id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "device_model" TEXT,
    "platform" TEXT NOT NULL DEFAULT 'android',
    "status" "DeviceStatus" NOT NULL,
    "activated_at" TIMESTAMPTZ(3),
    "last_seen_at" TIMESTAMPTZ(3),
    "revoked_at" TIMESTAMPTZ(3),
    "revoked_by" TEXT,
    "revoke_reason" TEXT,
    "replaced_by" TEXT,
    "replacement_for_device_id" TEXT,

    CONSTRAINT "devices_pkey" PRIMARY KEY ("company_id","id")
);

-- CreateTable
CREATE TABLE "device_replacement_requests" (
    "id" TEXT NOT NULL,
    "company_id" TEXT NOT NULL,
    "license_id" TEXT NOT NULL,
    "new_device_id" TEXT NOT NULL,
    "new_device_model" TEXT,
    "requested_by" TEXT NOT NULL,
    "reason" TEXT NOT NULL,
    "status" "ReplacementStatus" NOT NULL DEFAULT 'pending',
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "reviewed_by" TEXT,
    "reviewed_at" TIMESTAMPTZ(3),
    "review_reason" TEXT,
    "revoked_device_id" TEXT,

    CONSTRAINT "device_replacement_requests_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "audit_events" (
    "id" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "actor_id" TEXT,
    "company_id" TEXT,
    "license_id" TEXT,
    "device_id" TEXT,
    "reason" TEXT,
    "details" JSONB NOT NULL DEFAULT '{}',
    "at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_events_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "rate_limits" (
    "key" TEXT NOT NULL,
    "window_start" TIMESTAMPTZ(3) NOT NULL,
    "count" INTEGER NOT NULL,
    "expires_at" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "rate_limits_pkey" PRIMARY KEY ("key")
);

-- CreateTable
CREATE TABLE "invoice_number_counters" (
    "company_id" TEXT NOT NULL,
    "financial_year" TEXT NOT NULL,
    "last" INTEGER NOT NULL,
    "updated_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "invoice_number_counters_pkey" PRIMARY KEY ("company_id","financial_year")
);

-- CreateTable
CREATE TABLE "issued_invoice_numbers" (
    "company_id" TEXT NOT NULL,
    "invoice_id" TEXT NOT NULL,
    "invoice_number" TEXT NOT NULL,
    "financial_year" TEXT NOT NULL,
    "issued_by" TEXT NOT NULL,
    "issued_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "issued_invoice_numbers_pkey" PRIMARY KEY ("company_id","invoice_id")
);

-- CreateTable
CREATE TABLE "company_sync_state" (
    "company_id" TEXT NOT NULL,
    "seq" BIGINT NOT NULL DEFAULT 0,

    CONSTRAINT "company_sync_state_pkey" PRIMARY KEY ("company_id")
);

-- CreateTable
CREATE TABLE "clients" (
    "company_id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "notes" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "contact_person" TEXT,
    "phone" TEXT,
    "email" TEXT,
    "billing_address" TEXT,
    "gstin" TEXT,
    "created_at" TIMESTAMPTZ(3) NOT NULL,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),
    "created_by" TEXT NOT NULL,
    "updated_by" TEXT NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 1,
    "rev" INTEGER NOT NULL,
    "sync_seq" BIGINT NOT NULL,
    "server_updated_at" TIMESTAMPTZ(3) NOT NULL,
    "pushed_by" TEXT NOT NULL,
    "device_id" TEXT,

    CONSTRAINT "clients_pkey" PRIMARY KEY ("company_id","id")
);

-- CreateTable
CREATE TABLE "sites" (
    "company_id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "client_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "notes" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "address" TEXT,
    "contact_person" TEXT,
    "phone" TEXT,
    "default_hourly_rate_paise" BIGINT,
    "created_at" TIMESTAMPTZ(3) NOT NULL,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),
    "created_by" TEXT NOT NULL,
    "updated_by" TEXT NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 1,
    "rev" INTEGER NOT NULL,
    "sync_seq" BIGINT NOT NULL,
    "server_updated_at" TIMESTAMPTZ(3) NOT NULL,
    "pushed_by" TEXT NOT NULL,
    "device_id" TEXT,

    CONSTRAINT "sites_pkey" PRIMARY KEY ("company_id","id")
);

-- CreateTable
CREATE TABLE "machines" (
    "company_id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "notes" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "registration_number" TEXT,
    "serial_number" TEXT,
    "model" TEXT,
    "initial_meter_reading" INTEGER NOT NULL,
    "meter_unit" TEXT NOT NULL DEFAULT 'hours',
    "created_at" TIMESTAMPTZ(3) NOT NULL,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),
    "created_by" TEXT NOT NULL,
    "updated_by" TEXT NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 1,
    "rev" INTEGER NOT NULL,
    "sync_seq" BIGINT NOT NULL,
    "server_updated_at" TIMESTAMPTZ(3) NOT NULL,
    "pushed_by" TEXT NOT NULL,
    "device_id" TEXT,

    CONSTRAINT "machines_pkey" PRIMARY KEY ("company_id","id")
);

-- CreateTable
CREATE TABLE "operators" (
    "company_id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "notes" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "phone" TEXT,
    "code" TEXT,
    "created_at" TIMESTAMPTZ(3) NOT NULL,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),
    "created_by" TEXT NOT NULL,
    "updated_by" TEXT NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 1,
    "rev" INTEGER NOT NULL,
    "sync_seq" BIGINT NOT NULL,
    "server_updated_at" TIMESTAMPTZ(3) NOT NULL,
    "pushed_by" TEXT NOT NULL,
    "device_id" TEXT,

    CONSTRAINT "operators_pkey" PRIMARY KEY ("company_id","id")
);

-- CreateTable
CREATE TABLE "petrol_pumps" (
    "company_id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "notes" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "phone" TEXT,
    "address" TEXT,
    "created_at" TIMESTAMPTZ(3) NOT NULL,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),
    "created_by" TEXT NOT NULL,
    "updated_by" TEXT NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 1,
    "rev" INTEGER NOT NULL,
    "sync_seq" BIGINT NOT NULL,
    "server_updated_at" TIMESTAMPTZ(3) NOT NULL,
    "pushed_by" TEXT NOT NULL,
    "device_id" TEXT,

    CONSTRAINT "petrol_pumps_pkey" PRIMARY KEY ("company_id","id")
);

-- CreateTable
CREATE TABLE "work_logs" (
    "company_id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "work_date" DATE NOT NULL,
    "client_id" TEXT NOT NULL,
    "site_id" TEXT NOT NULL,
    "machine_id" TEXT NOT NULL,
    "operator_id" TEXT,
    "operator_name" TEXT,
    "start_reading" INTEGER NOT NULL,
    "start_captured_at" TIMESTAMPTZ(3),
    "start_lat" DOUBLE PRECISION,
    "start_lng" DOUBLE PRECISION,
    "start_accuracy" DOUBLE PRECISION,
    "start_location_status" TEXT,
    "end_reading" INTEGER,
    "end_captured_at" TIMESTAMPTZ(3),
    "end_lat" DOUBLE PRECISION,
    "end_lng" DOUBLE PRECISION,
    "end_accuracy" DOUBLE PRECISION,
    "end_location_status" TEXT,
    "working_hours" INTEGER,
    "entry_mode" TEXT NOT NULL,
    "manual_reason" TEXT,
    "notes" TEXT,
    "anomaly_flags" TEXT,
    "status" "WorkLogStatus" NOT NULL,
    "status_reason" TEXT,
    "approved_by" TEXT,
    "approved_at" TIMESTAMPTZ(3),
    "invoice_id" TEXT,
    "created_at" TIMESTAMPTZ(3) NOT NULL,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),
    "created_by" TEXT NOT NULL,
    "updated_by" TEXT NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 1,
    "rev" INTEGER NOT NULL,
    "sync_seq" BIGINT NOT NULL,
    "server_updated_at" TIMESTAMPTZ(3) NOT NULL,
    "pushed_by" TEXT NOT NULL,
    "device_id" TEXT,

    CONSTRAINT "work_logs_pkey" PRIMARY KEY ("company_id","id")
);

-- CreateTable
CREATE TABLE "fuel_entries" (
    "company_id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "filled_at" TIMESTAMPTZ(3) NOT NULL,
    "fuel_date" DATE NOT NULL,
    "machine_id" TEXT NOT NULL,
    "pump_id" TEXT NOT NULL,
    "client_id" TEXT,
    "site_id" TEXT,
    "litres_cl" INTEGER NOT NULL,
    "price_per_litre_paise" BIGINT NOT NULL,
    "total_paise" BIGINT NOT NULL,
    "receipt_captured_at" TIMESTAMPTZ(3),
    "receipt_lat" DOUBLE PRECISION,
    "receipt_lng" DOUBLE PRECISION,
    "receipt_accuracy" DOUBLE PRECISION,
    "receipt_location_status" TEXT,
    "notes" TEXT,
    "created_at" TIMESTAMPTZ(3) NOT NULL,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),
    "created_by" TEXT NOT NULL,
    "updated_by" TEXT NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 1,
    "rev" INTEGER NOT NULL,
    "sync_seq" BIGINT NOT NULL,
    "server_updated_at" TIMESTAMPTZ(3) NOT NULL,
    "pushed_by" TEXT NOT NULL,
    "device_id" TEXT,

    CONSTRAINT "fuel_entries_pkey" PRIMARY KEY ("company_id","id")
);

-- CreateTable
CREATE TABLE "invoices" (
    "company_id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "client_id" TEXT NOT NULL,
    "invoice_number" TEXT,
    "status" "InvoiceStatus" NOT NULL,
    "invoice_date" DATE NOT NULL,
    "period_from" DATE NOT NULL,
    "period_to" DATE NOT NULL,
    "payment_terms_days" INTEGER NOT NULL,
    "due_date" DATE NOT NULL,
    "notes" TEXT,
    "subtotal_paise" BIGINT NOT NULL,
    "discount_paise" BIGINT NOT NULL DEFAULT 0,
    "total_paise" BIGINT NOT NULL,
    "company_snapshot" TEXT,
    "client_snapshot" TEXT,
    "finalized_at" TIMESTAMPTZ(3),
    "finalized_by" TEXT,
    "cancelled_at" TIMESTAMPTZ(3),
    "cancelled_by" TEXT,
    "cancel_reason" TEXT,
    "created_at" TIMESTAMPTZ(3) NOT NULL,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "deleted_at" TIMESTAMPTZ(3),
    "created_by" TEXT NOT NULL,
    "updated_by" TEXT NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 1,
    "rev" INTEGER NOT NULL,
    "sync_seq" BIGINT NOT NULL,
    "server_updated_at" TIMESTAMPTZ(3) NOT NULL,
    "pushed_by" TEXT NOT NULL,
    "device_id" TEXT,

    CONSTRAINT "invoices_pkey" PRIMARY KEY ("company_id","id")
);

-- CreateTable
CREATE TABLE "invoice_lines" (
    "company_id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "invoice_id" TEXT NOT NULL,
    "work_log_id" TEXT NOT NULL,
    "work_date" DATE NOT NULL,
    "site_id" TEXT NOT NULL,
    "site_name" TEXT NOT NULL,
    "machine_id" TEXT NOT NULL,
    "machine_name" TEXT NOT NULL,
    "start_reading" INTEGER NOT NULL,
    "end_reading" INTEGER NOT NULL,
    "working_hours" INTEGER NOT NULL,
    "rate_paise" BIGINT NOT NULL,
    "amount_paise" BIGINT NOT NULL,
    "description" TEXT,
    "sort_order" INTEGER NOT NULL,

    CONSTRAINT "invoice_lines_pkey" PRIMARY KEY ("company_id","id")
);

-- CreateTable
CREATE TABLE "payments" (
    "company_id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "invoice_id" TEXT NOT NULL,
    "payment_date" DATE NOT NULL,
    "amount_paise" BIGINT NOT NULL,
    "method" TEXT NOT NULL,
    "reference" TEXT,
    "notes" TEXT,
    "reversed_at" TIMESTAMPTZ(3),
    "reversed_by" TEXT,
    "reverse_reason" TEXT,
    "created_at" TIMESTAMPTZ(3) NOT NULL,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,
    "created_by" TEXT NOT NULL,
    "updated_by" TEXT NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 1,
    "rev" INTEGER NOT NULL,
    "sync_seq" BIGINT NOT NULL,
    "server_updated_at" TIMESTAMPTZ(3) NOT NULL,
    "pushed_by" TEXT NOT NULL,
    "device_id" TEXT,

    CONSTRAINT "payments_pkey" PRIMARY KEY ("company_id","id")
);

-- CreateTable
CREATE TABLE "audit_logs" (
    "company_id" TEXT NOT NULL,
    "id" TEXT NOT NULL,
    "actor_id" TEXT NOT NULL,
    "action" TEXT NOT NULL,
    "entity_type" TEXT NOT NULL,
    "entity_id" TEXT NOT NULL,
    "details" TEXT,
    "created_at" TIMESTAMPTZ(3) NOT NULL,
    "rev" INTEGER NOT NULL,
    "sync_seq" BIGINT NOT NULL,
    "server_updated_at" TIMESTAMPTZ(3) NOT NULL,
    "pushed_by" TEXT NOT NULL,
    "device_id" TEXT,

    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("company_id","id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "refresh_tokens_token_hash_key" ON "refresh_tokens"("token_hash");

-- CreateIndex
CREATE INDEX "refresh_tokens_user_id_idx" ON "refresh_tokens"("user_id");

-- CreateIndex
CREATE INDEX "refresh_tokens_family_id_idx" ON "refresh_tokens"("family_id");

-- CreateIndex
CREATE INDEX "refresh_tokens_expires_at_idx" ON "refresh_tokens"("expires_at");

-- CreateIndex
CREATE UNIQUE INDEX "password_reset_tokens_token_hash_key" ON "password_reset_tokens"("token_hash");

-- CreateIndex
CREATE INDEX "password_reset_tokens_user_id_idx" ON "password_reset_tokens"("user_id");

-- CreateIndex
CREATE INDEX "companies_status_created_at_idx" ON "companies"("status", "created_at");

-- CreateIndex
CREATE INDEX "company_members_user_id_idx" ON "company_members"("user_id");

-- CreateIndex
CREATE INDEX "licenses_status_valid_until_idx" ON "licenses"("status", "valid_until");

-- CreateIndex
CREATE INDEX "licenses_valid_until_idx" ON "licenses"("valid_until");

-- CreateIndex
CREATE UNIQUE INDEX "licenses_company_id_id_key" ON "licenses"("company_id", "id");

-- CreateIndex
CREATE UNIQUE INDEX "licenses_company_id_activation_code_hash_key" ON "licenses"("company_id", "activation_code_hash");

-- CreateIndex
CREATE INDEX "devices_license_id_status_idx" ON "devices"("license_id", "status");

-- CreateIndex
CREATE INDEX "devices_status_last_seen_at_idx" ON "devices"("status", "last_seen_at" DESC);

-- CreateIndex
CREATE INDEX "devices_last_seen_at_idx" ON "devices"("last_seen_at" DESC);

-- CreateIndex
CREATE INDEX "device_replacement_requests_status_created_at_idx" ON "device_replacement_requests"("status", "created_at" DESC);

-- CreateIndex
CREATE INDEX "device_replacement_requests_created_at_idx" ON "device_replacement_requests"("created_at" DESC);

-- CreateIndex
CREATE INDEX "device_replacement_requests_company_id_new_device_id_idx" ON "device_replacement_requests"("company_id", "new_device_id");

-- CreateIndex
CREATE INDEX "audit_events_at_idx" ON "audit_events"("at" DESC);

-- CreateIndex
CREATE INDEX "audit_events_company_id_at_idx" ON "audit_events"("company_id", "at" DESC);

-- CreateIndex
CREATE INDEX "audit_events_license_id_at_idx" ON "audit_events"("license_id", "at" DESC);

-- CreateIndex
CREATE INDEX "audit_events_device_id_at_idx" ON "audit_events"("device_id", "at" DESC);

-- CreateIndex
CREATE INDEX "audit_events_type_at_idx" ON "audit_events"("type", "at" DESC);

-- CreateIndex
CREATE INDEX "rate_limits_expires_at_idx" ON "rate_limits"("expires_at");

-- CreateIndex
CREATE UNIQUE INDEX "issued_invoice_numbers_company_id_invoice_number_key" ON "issued_invoice_numbers"("company_id", "invoice_number");

-- CreateIndex
CREATE INDEX "clients_company_id_name_idx" ON "clients"("company_id", "name");

-- CreateIndex
CREATE UNIQUE INDEX "clients_company_id_sync_seq_key" ON "clients"("company_id", "sync_seq");

-- CreateIndex
CREATE INDEX "sites_company_id_client_id_idx" ON "sites"("company_id", "client_id");

-- CreateIndex
CREATE UNIQUE INDEX "sites_company_id_sync_seq_key" ON "sites"("company_id", "sync_seq");

-- CreateIndex
CREATE INDEX "machines_company_id_name_idx" ON "machines"("company_id", "name");

-- CreateIndex
CREATE UNIQUE INDEX "machines_company_id_sync_seq_key" ON "machines"("company_id", "sync_seq");

-- CreateIndex
CREATE INDEX "operators_company_id_name_idx" ON "operators"("company_id", "name");

-- CreateIndex
CREATE UNIQUE INDEX "operators_company_id_sync_seq_key" ON "operators"("company_id", "sync_seq");

-- CreateIndex
CREATE INDEX "petrol_pumps_company_id_name_idx" ON "petrol_pumps"("company_id", "name");

-- CreateIndex
CREATE UNIQUE INDEX "petrol_pumps_company_id_sync_seq_key" ON "petrol_pumps"("company_id", "sync_seq");

-- CreateIndex
CREATE INDEX "work_logs_company_id_work_date_idx" ON "work_logs"("company_id", "work_date");

-- CreateIndex
CREATE INDEX "work_logs_company_id_machine_id_idx" ON "work_logs"("company_id", "machine_id");

-- CreateIndex
CREATE INDEX "work_logs_company_id_status_idx" ON "work_logs"("company_id", "status");

-- CreateIndex
CREATE UNIQUE INDEX "work_logs_company_id_sync_seq_key" ON "work_logs"("company_id", "sync_seq");

-- CreateIndex
CREATE INDEX "fuel_entries_company_id_fuel_date_idx" ON "fuel_entries"("company_id", "fuel_date");

-- CreateIndex
CREATE UNIQUE INDEX "fuel_entries_company_id_sync_seq_key" ON "fuel_entries"("company_id", "sync_seq");

-- CreateIndex
CREATE INDEX "invoices_company_id_client_id_idx" ON "invoices"("company_id", "client_id");

-- CreateIndex
CREATE UNIQUE INDEX "invoices_company_id_sync_seq_key" ON "invoices"("company_id", "sync_seq");

-- CreateIndex
CREATE UNIQUE INDEX "invoices_company_id_invoice_number_key" ON "invoices"("company_id", "invoice_number");

-- CreateIndex
CREATE INDEX "invoice_lines_company_id_invoice_id_idx" ON "invoice_lines"("company_id", "invoice_id");

-- CreateIndex
CREATE INDEX "invoice_lines_company_id_work_log_id_idx" ON "invoice_lines"("company_id", "work_log_id");

-- CreateIndex
CREATE INDEX "payments_company_id_invoice_id_idx" ON "payments"("company_id", "invoice_id");

-- CreateIndex
CREATE UNIQUE INDEX "payments_company_id_sync_seq_key" ON "payments"("company_id", "sync_seq");

-- CreateIndex
CREATE INDEX "audit_logs_company_id_entity_type_entity_id_idx" ON "audit_logs"("company_id", "entity_type", "entity_id");

-- CreateIndex
CREATE UNIQUE INDEX "audit_logs_company_id_sync_seq_key" ON "audit_logs"("company_id", "sync_seq");

-- AddForeignKey
ALTER TABLE "developer_admins" ADD CONSTRAINT "developer_admins_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "refresh_tokens" ADD CONSTRAINT "refresh_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "password_reset_tokens" ADD CONSTRAINT "password_reset_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "companies" ADD CONSTRAINT "companies_owner_user_id_fkey" FOREIGN KEY ("owner_user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "company_members" ADD CONSTRAINT "company_members_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "company_members" ADD CONSTRAINT "company_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "licenses" ADD CONSTRAINT "licenses_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "devices" ADD CONSTRAINT "devices_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "devices" ADD CONSTRAINT "devices_company_id_license_id_fkey" FOREIGN KEY ("company_id", "license_id") REFERENCES "licenses"("company_id", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "device_replacement_requests" ADD CONSTRAINT "device_replacement_requests_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "device_replacement_requests" ADD CONSTRAINT "device_replacement_requests_company_id_license_id_fkey" FOREIGN KEY ("company_id", "license_id") REFERENCES "licenses"("company_id", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invoice_number_counters" ADD CONSTRAINT "invoice_number_counters_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "issued_invoice_numbers" ADD CONSTRAINT "issued_invoice_numbers_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "company_sync_state" ADD CONSTRAINT "company_sync_state_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "clients" ADD CONSTRAINT "clients_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sites" ADD CONSTRAINT "sites_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sites" ADD CONSTRAINT "sites_company_id_client_id_fkey" FOREIGN KEY ("company_id", "client_id") REFERENCES "clients"("company_id", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "machines" ADD CONSTRAINT "machines_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "operators" ADD CONSTRAINT "operators_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "petrol_pumps" ADD CONSTRAINT "petrol_pumps_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "work_logs" ADD CONSTRAINT "work_logs_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "work_logs" ADD CONSTRAINT "work_logs_company_id_client_id_fkey" FOREIGN KEY ("company_id", "client_id") REFERENCES "clients"("company_id", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "work_logs" ADD CONSTRAINT "work_logs_company_id_site_id_fkey" FOREIGN KEY ("company_id", "site_id") REFERENCES "sites"("company_id", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "work_logs" ADD CONSTRAINT "work_logs_company_id_machine_id_fkey" FOREIGN KEY ("company_id", "machine_id") REFERENCES "machines"("company_id", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "work_logs" ADD CONSTRAINT "work_logs_company_id_operator_id_fkey" FOREIGN KEY ("company_id", "operator_id") REFERENCES "operators"("company_id", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "fuel_entries" ADD CONSTRAINT "fuel_entries_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "fuel_entries" ADD CONSTRAINT "fuel_entries_company_id_machine_id_fkey" FOREIGN KEY ("company_id", "machine_id") REFERENCES "machines"("company_id", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "fuel_entries" ADD CONSTRAINT "fuel_entries_company_id_pump_id_fkey" FOREIGN KEY ("company_id", "pump_id") REFERENCES "petrol_pumps"("company_id", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "fuel_entries" ADD CONSTRAINT "fuel_entries_company_id_client_id_fkey" FOREIGN KEY ("company_id", "client_id") REFERENCES "clients"("company_id", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "fuel_entries" ADD CONSTRAINT "fuel_entries_company_id_site_id_fkey" FOREIGN KEY ("company_id", "site_id") REFERENCES "sites"("company_id", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invoices" ADD CONSTRAINT "invoices_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invoices" ADD CONSTRAINT "invoices_company_id_client_id_fkey" FOREIGN KEY ("company_id", "client_id") REFERENCES "clients"("company_id", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invoice_lines" ADD CONSTRAINT "invoice_lines_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invoice_lines" ADD CONSTRAINT "invoice_lines_company_id_invoice_id_fkey" FOREIGN KEY ("company_id", "invoice_id") REFERENCES "invoices"("company_id", "id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invoice_lines" ADD CONSTRAINT "invoice_lines_company_id_work_log_id_fkey" FOREIGN KEY ("company_id", "work_log_id") REFERENCES "work_logs"("company_id", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_company_id_invoice_id_fkey" FOREIGN KEY ("company_id", "invoice_id") REFERENCES "invoices"("company_id", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- ---------------------------------------------------------------------------
-- Integrity rules Prisma cannot express. They repeat the API's validation as
-- a last line of defence (also against manual SQL and imports).
-- ---------------------------------------------------------------------------

-- One pending replacement request per phone and company.
CREATE UNIQUE INDEX "device_replacement_requests_one_pending"
  ON "device_replacement_requests" ("company_id", "new_device_id")
  WHERE "status" = 'pending';

-- Case-insensitive company name search in the developer portal.
CREATE INDEX "companies_name_lower_idx" ON "companies" (lower("name"));

ALTER TABLE "users" ADD CONSTRAINT "users_email_lowercase" CHECK ("email" = lower("email"));

ALTER TABLE "licenses"
  ADD CONSTRAINT "licenses_max_devices_range" CHECK ("max_devices" BETWEEN 1 AND 100),
  ADD CONSTRAINT "licenses_dates_ordered" CHECK ("valid_until" > "valid_from");

ALTER TABLE "invoice_number_counters" ADD CONSTRAINT "invoice_number_counters_last_positive" CHECK ("last" >= 0);

ALTER TABLE "sites" ADD CONSTRAINT "sites_rate_non_negative"
  CHECK ("default_hourly_rate_paise" IS NULL OR "default_hourly_rate_paise" >= 0);

ALTER TABLE "machines" ADD CONSTRAINT "machines_meter_non_negative" CHECK ("initial_meter_reading" >= 0);

ALTER TABLE "work_logs"
  ADD CONSTRAINT "work_logs_start_non_negative" CHECK ("start_reading" >= 0),
  ADD CONSTRAINT "work_logs_hours_consistent" CHECK (
    "end_reading" IS NULL
    OR ("end_reading" >= "start_reading" AND "working_hours" = "end_reading" - "start_reading")
  );

ALTER TABLE "fuel_entries"
  ADD CONSTRAINT "fuel_entries_litres_positive" CHECK ("litres_cl" > 0),
  ADD CONSTRAINT "fuel_entries_price_non_negative" CHECK ("price_per_litre_paise" >= 0),
  ADD CONSTRAINT "fuel_entries_total_matches" CHECK (
    "total_paise" = ("litres_cl"::bigint * "price_per_litre_paise" + 50) / 100
  );

ALTER TABLE "invoices"
  ADD CONSTRAINT "invoices_discount_non_negative" CHECK ("discount_paise" >= 0),
  ADD CONSTRAINT "invoices_total_non_negative" CHECK ("total_paise" >= 0),
  ADD CONSTRAINT "invoices_total_matches" CHECK ("total_paise" = "subtotal_paise" - "discount_paise"),
  ADD CONSTRAINT "invoices_number_when_final" CHECK ("status" = 'draft' OR "invoice_number" IS NOT NULL);

ALTER TABLE "invoice_lines"
  ADD CONSTRAINT "invoice_lines_amounts_non_negative" CHECK ("rate_paise" >= 0 AND "amount_paise" >= 0),
  ADD CONSTRAINT "invoice_lines_hours_consistent" CHECK (
    "end_reading" >= "start_reading" AND "working_hours" = "end_reading" - "start_reading"
  );

ALTER TABLE "payments" ADD CONSTRAINT "payments_amount_positive" CHECK ("amount_paise" > 0);
