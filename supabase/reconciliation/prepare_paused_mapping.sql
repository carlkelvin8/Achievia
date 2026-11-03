-- Operator-only staging step, NOT an automatic migration. Populate this table
-- from verified deployed relationships, never guessed casts or row ordering.
begin;
create schema if not exists achievia_reconciliation;
revoke all on schema achievia_reconciliation from public, anon, authenticated;
-- Intentionally no IF NOT EXISTS: unexpected existing mapping must be reviewed.
create table achievia_reconciliation.paused_quiz_map (
  legacy_quiz_id uuid primary key,
  app_quiz_id integer not null,
  evidence text not null check (length(trim(evidence)) > 0)
);
revoke all on achievia_reconciliation.paused_quiz_map from public, anon, authenticated;
commit;
