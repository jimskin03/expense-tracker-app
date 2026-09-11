-- Generalize the shared account data relation so future services can reuse it.
-- Preserve existing rows when the legacy relation is already deployed.
do $$
begin
  if to_regclass('public.expense_tracker_data') is not null
     and to_regclass('public.financial_data') is null then
    alter table public.expense_tracker_data rename to financial_data;
  end if;
end
$$;

create table if not exists public.financial_data (
  user_id uuid primary key references auth.users(id) on delete cascade,
  incomes jsonb not null default '[]'::jsonb check (jsonb_typeof(incomes) = 'array'),
  expenses jsonb not null default '[]'::jsonb check (jsonb_typeof(expenses) = 'array'),
  recurring jsonb not null default '[]'::jsonb check (jsonb_typeof(recurring) = 'array'),
  updated_at timestamptz not null default now()
);

alter table public.financial_data enable row level security;

-- Recreate policies with domain-neutral names while preserving the same RLS rules.
drop policy if exists "Users can read their own expense tracker data" on public.financial_data;
drop policy if exists "Users can create their own expense tracker data" on public.financial_data;
drop policy if exists "Users can update their own expense tracker data" on public.financial_data;
drop policy if exists "Users can delete their own expense tracker data" on public.financial_data;
drop policy if exists "Users can read their own financial data" on public.financial_data;
drop policy if exists "Users can create their own financial data" on public.financial_data;
drop policy if exists "Users can update their own financial data" on public.financial_data;
drop policy if exists "Users can delete their own financial data" on public.financial_data;

create policy "Users can read their own financial data"
  on public.financial_data for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can create their own financial data"
  on public.financial_data for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "Users can update their own financial data"
  on public.financial_data for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "Users can delete their own financial data"
  on public.financial_data for delete
  to authenticated
  using ((select auth.uid()) = user_id);

revoke all on table public.financial_data from anon;
grant select, insert, update, delete on table public.financial_data to authenticated;
