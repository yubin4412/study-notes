-- 1회차 강의 질문 · 숙제 사이트 DB 설정
-- Supabase 대시보드 > SQL Editor 에 통째로 붙여넣고 Run 하면 끝. (급식 월드컵 표는 건드리지 않음)

-- 질문별 답 한 칸 = 한 줄
create table if not exists public.study_answers (
  page        text not null check (page ~ '^[a-z0-9-]{1,20}$'),
  qid         text not null check (qid ~ '^[A-Za-z0-9-]{1,40}$'),
  body        text not null default '' check (char_length(body) <= 20000),
  updated_at  timestamptz not null default now(),
  primary key (page, qid)
);

-- 고치기 전 내용을 남겨 두는 기록 (누가 실수로 지워도 대시보드에서 되살릴 수 있게)
create table if not exists public.study_answers_history (
  id          bigint generated always as identity primary key,
  page        text not null,
  qid         text not null,
  body        text not null,
  changed_at  timestamptz not null default now()
);

create or replace function public.study_answers_touch()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.updated_at := now();
  if tg_op = 'UPDATE' and old.body is distinct from new.body and old.body <> '' then
    insert into study_answers_history(page, qid, body) values (old.page, old.qid, old.body);
  end if;
  return new;
end;
$$;

drop trigger if exists study_answers_touch on public.study_answers;
create trigger study_answers_touch before insert or update on public.study_answers
  for each row execute function public.study_answers_touch();

alter table public.study_answers         enable row level security;
alter table public.study_answers_history enable row level security;

-- 링크를 가진 누구나 읽고 쓰기 (지우기는 대시보드에서만)
drop policy if exists "read answers" on public.study_answers;
create policy "read answers" on public.study_answers for select using (true);
drop policy if exists "add answers" on public.study_answers;
create policy "add answers" on public.study_answers for insert with check (true);
drop policy if exists "edit answers" on public.study_answers;
create policy "edit answers" on public.study_answers for update using (true) with check (true);

-- 기록 표는 정책을 안 만들어서 사이트에서는 못 읽고 못 씀 (대시보드에서만 봄)
