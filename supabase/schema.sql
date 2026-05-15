-- Run this in your Supabase SQL editor

create table if not exists users (
  id uuid primary key default gen_random_uuid(),
  email text unique not null,
  name text,
  user_type text default 'student',
  google_access_token text,
  google_refresh_token text,
  telegram_chat_id text,         -- comma-separated list of chat_ids
  telegram_last_update_id bigint, -- tracks consumed Telegram updates
  fcm_token text,
  created_at timestamptz default now()
);

-- Migration: run this if the table already exists
alter table users add column if not exists telegram_last_update_id bigint;

create table if not exists briefings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  content text not null,
  items_json text default '[]',
  generated_at timestamptz default now()
);

create table if not exists items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  source text not null,
  title text not null,
  body text,
  priority text,
  urgency_score int default 0,
  action_required boolean default false,
  deadline timestamptz,
  is_acknowledged boolean default false,
  raw_data jsonb,
  created_at timestamptz default now()
);

create table if not exists learning_materials (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  title text,
  source_text text,
  key_concepts jsonb,
  review_questions jsonb,
  next_review_date date,
  review_interval_days int default 1,
  created_at timestamptz default now()
);

-- Indexes
create index if not exists idx_briefings_user_id on briefings(user_id);
create index if not exists idx_items_user_id on items(user_id);
create index if not exists idx_items_priority on items(priority);
