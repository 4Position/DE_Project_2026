# Netflix Movie & Series Streaming Database: DBMS Project

**Course:** Database Management Systems · **Year:** B.Tech 2nd year · **Team size:** 4
**Database:** PostgreSQL 15 or newer · **Final submission:** Mon 23 Nov 2026
**Topics used:** Data types & constraints · Keys & relationships · Normalization · Query execution plans · Indexing · Query optimization · VACUUM/ANALYZE · Partitioning & sharding

## Files in this folder

| Path | What it is |
|------|------------|
| `README.md` | This project brief |
| `seed_data.zip` | 11 CSV files (200,401 viewing records): the only input for Phase 2. Unzip it to get `seed_data/` |
| `queries/workload_30.sql` | The 30 queries for Phase 3 (do not edit) |
| `benchmarks/run_benchmark.sh` | Timing script: 3 runs per query, average, raw plans saved |
| `CHECKPOINTS.md` | Checkpoint dates and the files each one needs (DE and AP repos) |

**Getting started:** **clone this repository and push it into your team's DE repo** (the DE repo you submitted in the form); the steps are in [`CHECKPOINTS.md`](CHECKPOINTS.md). Keep the structure shown in [Repository structure](#repository-structure-submit-exactly-this). Unzip `seed_data.zip` inside your project folder, but don't commit the CSV files. Deadlines are in [`CHECKPOINTS.md`](CHECKPOINTS.md). Then begin with Phase 1.

---

## Team details (fill in before you start)

| Role | Name | Enrollment No. | GitHub Username |
|------|------|----------------|-----------------|
| Group Lead | | | |
| Member 2 | | | |
| Member 3 | | | |
| Member 4 | | | |

**Team No.:** ____ · **Section:** ____ · **Repository URL:** ____

---

## How this project works

| Phase | What you do | You submit | Marks |
|-------|-------------|------------|------:|
| 1 | Understand the problem statements | `docs/01_problem_understanding.md` | 5 |
| 2 | Work out the database schema **from the seed data** and load it | `sql/01_schema.sql`, `sql/02_load_data.sql`, `docs/02_schema_design.md` | 25 |
| 3 | Run the **30 given SQL queries** and record their execution time | `docs/03_baseline_timings.md`, `benchmarks/results/baseline/` | 15 |
| 4 | Optimize the queries and record the new times | `sql/05_indexes.sql`, `sql/06_optimized_queries.sql`, `docs/04_optimization_report.md`, `benchmarks/results/optimized/` | 30 |
| 5 | Scalability test on the **large dataset** (given later by faculty) and final report | `docs/05_scalability_report.md`, `benchmarks/results/large/` | 25 |
| | **Total** | | **100** |

---

## Phase 1: Problem statements

Netflix sells monthly **plans** (Mobile, Basic, Standard, Premium) that differ in price, video quality and how many screens can stream at once. An **account** can have up to 5 **profiles**; kids profiles are limited to U/UA7 content. The catalogue has **movies** and **series** (series have seasons and episodes) tagged with genres; some titles are Netflix Originals, and licensed titles eventually leave the service. Every play is recorded in **viewing activity**, profiles rate titles and keep a **My List**, and every month each account is **invoiced**. You have joined the Netflix India data team.

The current database was put together quickly by an earlier team. It has **no documented schema** (only data exports survive), and the product teams are complaining:

| # | Problem reported | Team | Related queries |
|---|------------------|------|-----------------|
| P1 | "Home-screen rows (**Continue Watching, Top 10, My List, genre rows**) render slowly." | Personalization / UI | R01, R03, R04, R06, R22, R25 |
| P2 | "**Title pages, autoplay of the next episode** and search feel laggy." | Playback / Search | R02, R05, R07, W01 |
| P3 | "**Sign-in** with an email typed in different case is slow, and profile switching lags." | Identity | R10, R24, W03 |
| P4 | "The content team's "**episodes nobody watched**" report is always **empty**." | Content strategy | R13 |
| P5 | "**Billing**: retry lists, on-hold accounts, the monthly billing run and dunning job are too slow." | Payments & Billing | R11, R21, W04, W05 |
| P6 | "**Compliance** must prove kids profiles never watch content above their limit, and detect **account sharing**." | Compliance / Trust | R14, R16 |
| P7 | "Analytics (binge sessions, completion rates, device hours, originals, ratings, My List adds) time out, and viewing will grow **20×**." | Content analytics | R08, R09, R17, R18, R19, R20, W02 |
| P8 | "Finance needs **plan revenue and churn** reports; support needs a fast activity console." | Finance / Support | R12, R15, R23 |

**Your job:**
1. Rebuild a correct, well-constrained schema from the data exports (Phase 2).
2. Measure how the 30 most important queries perform today (Phase 3).
3. Make them fast **without changing their results** (Phase 4).
4. Prove the database will survive next year's growth (Phase 5).

**Deliverable for Phase 1** (`docs/01_problem_understanding.md`, at most 1 page):
- For each problem P1–P8, write in your own words what the business needs and which **stakeholder** is affected (member/profile, kids profile, parents, personalization/UI rows, content strategy, payments & billing, finance, compliance, support).
- Classify each problem as **customer-facing / real-time** or **reporting / analytics**. This decides your performance targets later.
- List any assumptions you make.

---

## Phase 2: Work out the schema from the seed data

You receive **`seed_data.zip`**. Unzip it to get a folder **`seed_data/`** with 11 CSV files, a real export of the production data:

| File | Rows | What it contains |
|------|-----:|------------------|
| `plans.csv` | 4 | Subscription plans |
| `accounts.csv` | 25,000 | Paying accounts (one per household) |
| `profiles.csv` | 75,000 | Profiles inside each account (including kids profiles) |
| `genres.csv` | 15 | Genres |
| `titles.csv` | 3,000 | Movies and series in the catalogue |
| `title_genres.csv` | 5,963 | Genres of each title |
| `episodes.csv` | 20,000 | Episodes of each series |
| `viewing_activity.csv` | 200,401 | Every play from 1 Jan 2025 to 30 Jun 2026 |
| `ratings.csv` | 33,900 | Thumbs down / thumbs up / love ratings |
| `my_list.csv` | 59,992 | Titles saved to each profile's My List |
| `invoices.csv` | 133,057 | Monthly invoices (January–June 2026) |

The first line of every file is the header (column names). Here are the headers and the first rows of each file:

**plans.csv**
```
plan_id,plan_name,monthly_price_inr,max_streams,max_resolution,has_ads
1,MOBILE,149.00,1,480p,f
2,BASIC,199.00,1,720p,f
```

**accounts.csv**
```
account_id,email,phone,country_code,plan_id,signup_date,status,cancelled_on,next_billing_date
1,vivaan.sharma1@yahoo.com,7000000001,IN,1,2023-09-09,CANCELLED,2026-02-02,
2,aditya.sharma2@yahoo.com,,IN,1,2020-01-04,ACTIVE,,2026-07-01
```

**profiles.csv**
```
profile_id,account_id,profile_name,is_kids,maturity_limit,language,created_at
1,1,vivaan,f,A,English,2023-09-09 00:00:00+05:30
2,1,Dadi,f,UA13,English,2023-09-19 00:00:00+05:30
```

**genres.csv**
```
genre_id,genre_name
1,Drama
2,Comedy
```

**titles.csv**
```
title_id,title_type,name,release_year,maturity_rating,original_language,runtime_min,is_netflix_original,added_on,leaving_on
1,MOVIE,Love in Mumbai,2012,UA13,English,149,f,2024-11-28,
2,MOVIE,Midnight Mumbai,2022,A,Japanese,104,f,2021-09-06,
```

**title_genres.csv**
```
title_id,genre_id
1,8
1,13
```

**episodes.csv**
```
episode_id,title_id,season_no,episode_no,episode_title,runtime_min,release_date
1,2001,1,1,Episode 1: Fault Lines,34,2023-12-01
2,2001,1,2,Episode 2: Homecoming,35,2023-12-01
```

**viewing_activity.csv**
```
view_id,profile_id,title_id,episode_id,started_at,duration_watched_sec,device_type,completed
1,40206,1338,,2025-01-01 00:00:00+05:30,4991,TV,f
2,25066,1131,,2025-01-01 00:05:36+05:30,6252,MOBILE,f
```

**ratings.csv**
```
profile_id,title_id,rating,rated_at
1,2022,LOVE,2025-05-17 00:31:17+05:30
6,560,THUMBS_UP,2026-04-24 14:20:44+05:30
```

**my_list.csv**
```
profile_id,title_id,added_at
1,1205,2026-03-31 12:05:27+05:30
1,1643,2025-05-20 16:03:39+05:30
```

**invoices.csv**
```
invoice_id,account_id,billing_period_start,amount_inr,status,paid_at
1,1,2026-01-01,149.00,PAID,2026-01-01 20:00:00+05:30
2,2,2026-01-01,149.00,PAID,2026-01-01 14:00:00+05:30
```

Open the files yourself (a spreadsheet, `head`, or `SELECT` after a quick load into a scratch table) and study the data carefully. **Nobody will give you the CREATE TABLE statements.** Working them out *is* the task.

### 2.1 What you must identify (for every table)
1. **Table name and column names.** Use exactly the file names and CSV headers. The 30 queries depend on them.
2. **Data type** of every column. Choose the *right* type, not just `TEXT` everywhere. Think about money, timestamps with a time-zone offset, yes/no columns, small whole numbers, decimals and short codes.
3. **Primary key.** Is it one column, or a combination? (Look closely at `title_genres`, `ratings`, `my_list`, and what identifies an episode inside a series.)
4. **Foreign keys.** Which column points to which table? What should happen **ON DELETE** (CASCADE, RESTRICT or SET NULL), and why?
5. **NOT NULL vs NULL.** Some columns are empty in some rows. Find out **when** and **why**, and decide which columns must never be empty. Why do some viewing records have no `episode_id`? When are `runtime_min`, `leaving_on`, `cancelled_on`, `next_billing_date`, `phone` and `paid_at` empty?
6. **UNIQUE** columns (natural candidate keys such as emails, phone numbers, codes and handles).
7. **CHECK constraints.** Write at least **12** that the data obeys and the business needs. Look for allowed values (plans, statuses, maturity ratings, devices, rating values), ranges (streams, runtimes, years), and rules tying columns together (movies have a runtime but series don't, a cancelled account has a cancellation date, kids profiles are limited to U/UA7, failed invoices have no payment time, invoices start on the 1st of a month, Originals never leave).
8. **Relationships and cardinalities** (1:1, 1:N, M:N). Draw the **ER diagram** (image + Mermaid code).
9. **Normal form.** Show that each table is in 3NF/BCNF (list its functional dependencies). Point out any column that is *derived or redundant* (hint: `viewing_activity.completed` vs `duration_watched_sec` and runtime; `invoices.amount_inr` vs the plan price; `viewing_activity.title_id` vs the episode's series) and say whether keeping it is justified.

### 2.2 Rules for your schema
- Create every table in a schema named **`netflix`**: `CREATE SCHEMA netflix;` and `SET search_path TO netflix;`
- In this phase create **only constraints**: PK, FK, UNIQUE, NOT NULL, CHECK. **Do not create any other index yet.** (PostgreSQL automatically indexes PRIMARY KEY and UNIQUE columns; that's allowed. Note which indexes exist.) Your baseline in Phase 3 must reflect a database *without* tuning.
- Your constraints must accept **all** rows of the seed data. If a load fails, either your constraint is wrong or you found a data problem. Explain which in your design doc.

### 2.3 Load the data
Write `sql/02_load_data.sql` using `\copy`, loading tables in the right order (parents before children):

```sql
SET search_path TO netflix;
\copy plans FROM 'seed_data/plans.csv' WITH (FORMAT csv, HEADER true)
-- ... the other tables, in an order that satisfies your foreign keys
ANALYZE;
```

Then verify the row counts match the table above, and run at least **3 integrity checks** of your own (e.g. "nobody watched a title before it was added", "an episode in viewing_activity belongs to the same series as its title_id", "each account has at most 5 profiles"). Paste the results into `docs/02_schema_design.md`.

### Phase 2 deliverables
- `sql/01_schema.sql`: runs top-to-bottom on an empty database without errors
- `sql/02_load_data.sql`: loads all 11 files without errors
- `docs/02_schema_design.md`: data dictionary (table · column · type · constraint · *why*), ER diagram, FDs and normal form per table, integrity-check results, and every data problem you found

---

## Phase 3: Run the 30 queries and record the time

The file **`queries/workload_30.sql`** contains **30 queries**: 25 reads (`R01`–`R25`) and 5 writes (`W01`–`W05`). They're also listed in the [Appendix](#appendix-the-30-queries). **Do not modify them.** If a query fails, your schema doesn't match the seed data; fix the schema, not the query.

### 3.1 How to measure (everyone must use the same method)
- Run each query with `EXPLAIN (ANALYZE, BUFFERS)` and read the **`Execution Time`** at the bottom.
- Run each query **3 times** and record the **average** of the three `Execution Time` values. Keep all three runs in the raw plan file.
- Write queries (`W01`–`W05`) must be measured inside `BEGIN; … ROLLBACK;` so the data does not change.
- Close other heavy applications while measuring, and use the **same laptop** for Phase 3 and Phase 4.

The helper script does all of this for you:
```bash
./benchmarks/run_benchmark.sh <your_database> baseline
# → benchmarks/results/baseline/summary.csv   (avg, median, min, max, scan types)
# → benchmarks/results/baseline/R01.txt …     (full plans of all 3 runs)
```
> ⚠️ One of the 30 queries takes **several seconds** on the seed data. That's intentional. Let it finish, and don't skip it.

### 3.2 Deliverable: the timing table
In `docs/03_baseline_timings.md`, fill this table for **all 30** queries:

| SQL Query | Type | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) |
|---|---|---:|---:|---:|---:|
| R01: "Continue Watching" row: the latest unfinished viewing per title for profile 7043 | READ | | | | |
| R02: Title page: seasons of series 2909 with the number of episodes in each | READ | | | | |
| R03: "Top 10 in India today" row: most-watched titles on 30 June 2026 | READ | | | | |
| R04: Genre row for a kids profile: Comedy titles rated U or UA7, newest additions first | READ | | | | |
| R05: Search: titles whose name contains "love" | READ | | | | |
| R06: "My List" row for profile 7393 | READ | | | | |
| R07: Autoplay: the next episode of series 2909 after season 1 episode 4 | READ | | | | |
| R08: Insights: binge sessions in June 2026 (3+ episodes of one series by one profile on one day) | READ | | | | |
| R09: Content analytics: completion rate per genre (2026) | READ | | | | |
| R10: Sign-in: find the account by email, ignoring case | READ | | | | |
| R11: Payments: active accounts whose June 2026 invoice failed (retry list) | READ | | | | |
| R12: Retention: cancellations per month in 2026 and average tenure (days) of those accounts | READ | | | | |
| R13: Content team: episodes of series 2523 that nobody has watched | READ | | | | |
| R14: Compliance: kids profiles that watched titles above their maturity limit | READ | | | | |
| R15: Finance: active accounts and monthly recurring revenue per plan | READ | | | | |
| R16: Account sharing check: accounts with more profiles watching in the same hour than their plan's streams | READ | | | | |
| R17: Content strategy: share of "LOVE" ratings for Netflix Originals vs licensed titles | READ | | | | |
| R18: Device analytics: viewing hours per device per month in 2026 | READ | | | | |
| R19: Originals report: total views and the most recent view of every Netflix Original | READ | | | | |
| R20: Marketing: 10 titles added to the most My Lists in June 2026 | READ | | | | |
| R21: Payments: accounts on hold whose billing date has already passed | READ | | | | |
| R22: "Last chance to watch" row: licensed titles leaving in July 2026 | READ | | | | |
| R23: Support console: all viewing activity, newest first, page 6,001 (25 per page) | READ | | | | |
| R24: "Who's watching?" screen: profiles of account 1409 | READ | | | | |
| R25: "More like this": titles sharing at least 2 genres with series 2909 | READ | | | | |
| W01: Player: profile 7043 starts episode S1E5 of series 2909 | WRITE | | | | |
| W02: "+ My List": profile 7043 adds series 2523 | WRITE | | | | |
| W03: Account settings: account 1409 downgrades to the STANDARD plan | WRITE | | | | |
| W04: Monthly billing run: create July 2026 invoices for every active account | WRITE | | | | |
| W05: Dunning: put active accounts whose latest invoice failed on hold | WRITE | | | | |
| **Total (sum of all 30)** | | | | | |

Below the table, add for each query the **scan type** from the plan (Seq Scan, Index Scan, …) and one line on **why** it is slow or fast.

---

## Phase 4: Optimize the queries

Make the queries faster. **The results must stay the same** (same rows; order matters only where the query has an `ORDER BY`).

### 4.1 Techniques you may use
| Technique | Example |
|-----------|---------|
| B-tree index (single / composite) | the right column **order** matters: equality columns first, then range/sort |
| Partial index | index only the rows a query needs (e.g. a rare status) |
| Covering index | `INCLUDE (...)` so the table is never visited (Index Only Scan) |
| Expression index | index the exact expression used in `WHERE` |
| GIN index | for `ILIKE '%text%'` (extension `pg_trgm`), arrays or full-text search |
| BRIN index | for huge tables stored in time order |
| Query rewrite | sargable date ranges instead of functions on columns; `NOT EXISTS` instead of `NOT IN`; joins instead of correlated subqueries; keyset instead of `OFFSET` pagination; `UNION ALL` instead of `OR` across columns |
| VACUUM / ANALYZE | fresh statistics and visibility maps |
| Summary table / materialized view | for heavy reports that don't need live data (state how it's refreshed) |

**Not allowed:** changing the data, deleting rows, changing PostgreSQL server settings to hide the problem (e.g. huge `work_mem`, `enable_seqscan = off`), or caching results outside the database.

### 4.2 How to work
1. Put every index in `sql/05_indexes.sql`, each with a comment: **which queries it serves and why this type and column order**.
2. Put rewritten queries in `sql/06_optimized_queries.sql`. Copy `queries/workload_30.sql` and change **only** the queries you rewrite, keeping the `-- @R01` markers.
3. **Prove the results are unchanged** for every rewritten query (compare row counts, plus a checksum or an `EXCEPT` query). Put the proof in your report.
4. Benchmark again with the same method:
```bash
./benchmarks/run_benchmark.sh <your_database> optimized 5 sql/06_optimized_queries.sql
```
> 🔎 **Read the results, not just the timings.** At least one of the 30 original queries returns a **wrong answer** because of a subtle SQL rule about NULLs. Find it, explain it, and fix it. This is worth marks.

### 4.3 Deliverable: the optimization table
In `docs/04_optimization_report.md`:

| Query | Before (ms) | Problem found in the plan | Optimization applied | After (ms) | Improvement | Same result? |
|-------|------------:|---------------------------|----------------------|-----------:|------------:|:------------:|
| R01 | | e.g. Seq Scan on 200k viewing rows | e.g. index on `viewing_activity(profile_id, started_at DESC)` | | e.g. 99% (150×) | ✅ |
| … all 30 … | | | | | | |
| **Total** | | | | | | |

Improvement % = (before − after) / before × 100

Also include:
- **Before/after `EXPLAIN` plans** for your 5 biggest improvements
- **Write overhead:** which write queries got **slower** because of your indexes, by how much, and whether that's acceptable
- **Index storage:** the size of each index you created (`pg_relation_size`) compared with its table
- **Queries you could not speed up**, and why (an honest "this query must read most of the table" earns marks)

---

## Phase 5: Scalability report (large dataset round)

Your optimizations worked on 200,401 viewing records. Next year the business expects **20× the volume**.

By **Thu 19 Nov 2026**, faculty will release **`large_data.zip`**: the same 11 CSV files with about **20× the rows** (≈ 4,008,000 viewing activity, ≈ 2,661,000 invoices, ≈ 1,500,000 profiles, ≈ 500,000 accounts). Until then, work on the design part of the report.

### 5.1 What to do with the large dataset
1. Create a new database. Run **your** `01_schema.sql`, load `large_data/` with your load script (change the folder name only), then run **your** `05_indexes.sql` and `ANALYZE`.
2. Run your **optimized** queries (`sql/06_optimized_queries.sql`). **Do not run the original 30 on the large data.** Some of them could run for a very long time.
   - R23 pages with `OFFSET`; if you replaced it with keyset pagination, explain how the "last seen" value is chosen for the large data.
3. Record the times and compare with your Phase 4 results on the seed data.

| Query | Optimized on seed (ms) | Optimized on large (ms) | Growth (large ÷ seed) | Meets target? | If not, what you changed |
|-------|------------------------:|------------------------:|----------------------:|:-------------:|--------------------------|
| R01 | | | | | |
| … all 30 … | | | | | |

### 5.2 Performance targets on the large dataset
| Query group | Queries | Target (average of 3 runs) |
|-------------|---------|----------------:|
| Real-time / member-facing | R01, R02, R06, R07, R10, R24, W01, W02, W03 | **under 5 ms** |
| Interactive rows, search and ops | R03, R04, R05, R11, R13, R21, R22, R23, R25 | **under 250 ms** |
| Reports and analytics | R08, R09, R12, R14, R15, R16, R17, R18, R19, R20 | **under 5,000 ms** |
| Batch jobs | W04, W05 | **under 2,000 ms** |

If a query misses its target, **find out why from the plan and fix it.** A query that was fast on the seed data can become slow on large data for reasons that only appear at scale. Show the before/after plans for every fix.

### 5.3 Deliverable: `docs/05_scalability_report.md`
1. **Results table** (above), with every target met or explained.
2. **Growth analysis.** Group your queries by how their time grew when the data grew 20×:
   - *stayed about the same* (why? e.g. index lookups grow with log n)
   - *grew about 20×* (why? e.g. they read a fixed *share* of the table)
   - *grew more than 20×* (why, and what you did about it)
3. **What broke at scale** and how you fixed it (plans before/after).
4. **Storage:** total database size, table vs index size, on seed and large data.
5. **Architecture for 100×:** explain with numbers from your own measurements:
   - **Partitioning:** which table, by which column (RANGE / LIST / HASH), and why. Write the DDL for `viewing_activity`, show partition pruning with `EXPLAIN`, and note the primary-key rule for partitioned tables.
   - **Sharding:** Would you shard by account, by profile, or by title? Think about Continue Watching (one profile) vs Top 10 and Originals reports (one title, all viewers). Which queries become cross-shard, and how would you handle them?
   - **Read replicas and caching:** which of the 30 queries you would send to a replica or cache, and which must hit the primary.
   - **Maintenance:** VACUUM/autovacuum settings for `viewing_activity`, archiving old data, refreshing summary tables.
6. **Conclusion:** is your database ready for next year? What are the remaining risks?

---

## Repository structure (submit exactly this)

```
netflix-dbms-<team-no>/
├── README.md                          # team table, how to run, headline numbers
├── team.json                          # group lead, members, enrollment numbers
├── docs/
│   ├── 01_problem_understanding.md
│   ├── 02_schema_design.md
│   ├── 03_baseline_timings.md
│   ├── 04_optimization_report.md
│   └── 05_scalability_report.md
├── diagrams/
│   └── er_diagram.png
├── sql/
│   ├── 01_schema.sql
│   ├── 02_load_data.sql
│   ├── 05_indexes.sql
│   ├── 06_optimized_queries.sql
│   └── 08_partitioning.sql
├── queries/
│   └── workload_30.sql                # given; do not edit
└── benchmarks/
    ├── run_benchmark.sh               # given
    └── results/
        ├── baseline/                  # Phase 3: summary.csv + raw plans
        ├── optimized/                 # Phase 4
        └── large/                     # Phase 5
```

`team.json`:
```json
{
  "team_number": "",
  "group_lead": { "name": "", "enrollment_no": "", "github": "" },
  "members": [
    { "name": "", "enrollment_no": "", "github": "" },
    { "name": "", "enrollment_no": "", "github": "" },
    { "name": "", "enrollment_no": "", "github": "" }
  ],
  "postgres_version": "",
  "laptop_used_for_benchmarks": ""
}
```

**Do not commit the CSV files** (`seed_data/`, `large_data/`); add them to `.gitignore`. They are too large and we already have them.

---

## Timeline

| Due | Work | Checkpoint |
|-----|------|------------|
| Mon 2 Nov 2026 | Clone this repo into your team's DE repo, add members, commit `team.json` | **CP0** Setup |
| Mon 16 Nov 2026 | Phase 1 + Phase 2 (schema, load, ER, data dictionary) | **CP1** Schema loads all seed data with no errors |
| Tue 17 Nov 2026 | Phase 3 (baseline, 3 runs, average) + start Phase 4 | **CP2** Baseline table for all 30 queries committed |
| Thu 19 Nov 2026 | Phase 4 (indexes, rewrites, wrong-result query) | **CP3** Optimization table committed |
| Mon 23 Nov 2026 | Phase 5 on the large dataset + final report | **CP4 Final submission:** last commit on the default branch |
| Wed 25 – Thu 26 Nov 2026 | Individual analysis, in class time | **CP5** Individual analysis |

Full list of files per checkpoint, including the AP repo: [`CHECKPOINTS.md`](CHECKPOINTS.md).

---

## Evaluation (100 marks)

| Phase | Criteria | Marks |
|-------|----------|------:|
| 1 | Problems understood, stakeholders and query groups correctly identified | 5 |
| 2 | Correct data types (6), keys and foreign keys with justified delete rules (6), ≥12 meaningful CHECK / NOT NULL / UNIQUE constraints (6), ER diagram + normal-form analysis (4), data loads cleanly + integrity checks (3) | 25 |
| 3 | All 30 queries measured with the required method (8), raw plans committed (3), scan type and reason for each query (4) | 15 |
| 4 | Speed-up achieved with appropriate techniques (12), every index justified (5), results proven unchanged (4), wrong-result query found and explained (4), write overhead and index storage reported (5) | 30 |
| 5 | Large-dataset results with all targets met or explained (8), growth analysis (6), scale-only problems found and fixed (5), partitioning DDL + sharding/replica design backed by your numbers (6) | 25 |

**Integrity rules**
- Every number in your reports must match the raw plan files in `benchmarks/results/`. Copied or invented timings make the whole phase score 0.
- Every member must have commits; the commit history is checked.
- You may use AI tools to learn, but you must be able to explain every index and rewrite in your individual analysis.

---

## Appendix: the 30 queries

These are identical to `queries/workload_30.sql`. Use the file, not copy-paste from this page.

**R01: "Continue Watching" row: the latest unfinished viewing per title for profile 7043**
```sql
SELECT DISTINCT ON (v.title_id) v.title_id, t.name, v.episode_id, v.duration_watched_sec, v.started_at
FROM viewing_activity v
JOIN titles t ON t.title_id = v.title_id
WHERE v.profile_id = 7043 AND NOT v.completed
ORDER BY v.title_id, v.started_at DESC;
```

**R02: Title page: seasons of series 2909 with the number of episodes in each**
```sql
SELECT season_no, count(*) AS episodes, min(release_date) AS released
FROM episodes
WHERE title_id = 2909
GROUP BY season_no
ORDER BY season_no;
```

**R03: "Top 10 in India today" row: most-watched titles on 30 June 2026**
```sql
SELECT t.title_id, t.name, count(DISTINCT v.profile_id) AS viewers
FROM viewing_activity v
JOIN titles t ON t.title_id = v.title_id
WHERE v.started_at >= '2026-06-30' AND v.started_at < '2026-07-01'
GROUP BY t.title_id, t.name
ORDER BY viewers DESC
LIMIT 10;
```

**R04: Genre row for a kids profile: Comedy titles rated U or UA7, newest additions first**
```sql
SELECT t.title_id, t.name, t.maturity_rating, t.added_on
FROM titles t
JOIN title_genres tg ON tg.title_id = t.title_id
JOIN genres g        ON g.genre_id = tg.genre_id
WHERE g.genre_name = 'Comedy'
  AND t.maturity_rating IN ('U', 'UA7')
ORDER BY t.added_on DESC
LIMIT 40;
```

**R05: Search: titles whose name contains "love"**
```sql
SELECT title_id, name, title_type, release_year
FROM titles
WHERE name ILIKE '%love%'
ORDER BY release_year DESC
LIMIT 30;
```

**R06: "My List" row for profile 7393**
```sql
SELECT t.title_id, t.name, t.title_type, m.added_at
FROM my_list m
JOIN titles t ON t.title_id = m.title_id
WHERE m.profile_id = 7393
ORDER BY m.added_at DESC;
```

**R07: Autoplay: the next episode of series 2909 after season 1 episode 4**
```sql
SELECT episode_id, season_no, episode_no, episode_title
FROM episodes
WHERE title_id = 2909
  AND (season_no, episode_no) > (1, 4)
ORDER BY season_no, episode_no
LIMIT 1;
```

**R08: Insights: binge sessions in June 2026 (3+ episodes of one series by one profile on one day)**
```sql
SELECT profile_id, title_id, started_at::date AS day, count(*) AS episodes
FROM viewing_activity
WHERE episode_id IS NOT NULL
  AND started_at >= '2026-06-01'
GROUP BY profile_id, title_id, started_at::date
HAVING count(*) >= 3
ORDER BY episodes DESC, day;
```

**R09: Content analytics: completion rate per genre (2026)**
```sql
SELECT g.genre_name, count(*) AS views,
       round(100.0 * count(*) FILTER (WHERE v.completed) / count(*), 1) AS completion_pct
FROM viewing_activity v
JOIN title_genres tg ON tg.title_id = v.title_id
JOIN genres g        ON g.genre_id = tg.genre_id
WHERE EXTRACT(YEAR FROM v.started_at) = 2026
GROUP BY g.genre_name
ORDER BY completion_pct DESC;
```

**R10: Sign-in: find the account by email, ignoring case**
```sql
SELECT account_id, plan_id, status
FROM accounts
WHERE lower(email) = 'arjun.chopra1409@yahoo.com';
```

**R11: Payments: active accounts whose June 2026 invoice failed (retry list)**
```sql
SELECT i.invoice_id, i.account_id, i.amount_inr
FROM invoices i
JOIN accounts a ON a.account_id = i.account_id
WHERE i.status = 'FAILED'
  AND i.billing_period_start = '2026-06-01'
  AND a.status IN ('ACTIVE', 'ON_HOLD')
ORDER BY i.account_id;
```

**R12: Retention: cancellations per month in 2026 and average tenure (days) of those accounts**
```sql
SELECT date_trunc('month', cancelled_on) AS month, count(*) AS cancellations,
       round(avg(cancelled_on - signup_date), 0) AS avg_tenure_days
FROM accounts
WHERE status = 'CANCELLED'
  AND EXTRACT(YEAR FROM cancelled_on) = 2026
GROUP BY 1
ORDER BY 1;
```

**R13: Content team: episodes of series 2523 that nobody has watched**
```sql
SELECT e.episode_id, e.season_no, e.episode_no
FROM episodes e
WHERE e.title_id = 2523
  AND e.episode_id NOT IN (SELECT v.episode_id FROM viewing_activity v);
```

**R14: Compliance: kids profiles that watched titles above their maturity limit**
```sql
SELECT p.profile_id, p.maturity_limit, t.title_id, t.maturity_rating, v.started_at
FROM viewing_activity v
JOIN profiles p ON p.profile_id = v.profile_id
JOIN titles t   ON t.title_id = v.title_id
WHERE p.is_kids
  AND array_position(ARRAY['U','UA7','UA13','UA16','A'], t.maturity_rating)
      > array_position(ARRAY['U','UA7','UA13','UA16','A'], p.maturity_limit)
ORDER BY v.started_at DESC;
```

**R15: Finance: active accounts and monthly recurring revenue per plan**
```sql
SELECT p.plan_name, count(*) AS accounts, sum(p.monthly_price_inr) AS monthly_revenue_inr
FROM accounts a
JOIN plans p ON p.plan_id = a.plan_id
WHERE a.status = 'ACTIVE'
GROUP BY p.plan_name
ORDER BY monthly_revenue_inr DESC;
```

**R16: Account sharing check: accounts with more profiles watching in the same hour than their plan's streams**
```sql
SELECT pr.account_id, date_trunc('hour', v.started_at) AS hour, count(DISTINCT v.profile_id) AS profiles_watching, pl.max_streams
FROM viewing_activity v
JOIN profiles pr ON pr.profile_id = v.profile_id
JOIN accounts a  ON a.account_id = pr.account_id
JOIN plans pl    ON pl.plan_id = a.plan_id
GROUP BY pr.account_id, date_trunc('hour', v.started_at), pl.max_streams
HAVING count(DISTINCT v.profile_id) > pl.max_streams
ORDER BY profiles_watching DESC;
```

**R17: Content strategy: share of "LOVE" ratings for Netflix Originals vs licensed titles**
```sql
SELECT t.is_netflix_original,
       count(*) AS ratings,
       round(100.0 * count(*) FILTER (WHERE r.rating = 'LOVE') / count(*), 1) AS love_pct
FROM ratings r
JOIN titles t ON t.title_id = r.title_id
GROUP BY t.is_netflix_original;
```

**R18: Device analytics: viewing hours per device per month in 2026**
```sql
SELECT date_trunc('month', started_at) AS month, device_type, round(sum(duration_watched_sec) / 3600.0, 0) AS hours
FROM viewing_activity
WHERE started_at::date >= '2026-01-01'
GROUP BY 1, 2
ORDER BY 1, 2;
```

**R19: Originals report: total views and the most recent view of every Netflix Original**
```sql
SELECT t.title_id, t.name,
       (SELECT count(*) FROM viewing_activity v WHERE v.title_id = t.title_id) AS total_views,
       (SELECT max(v.started_at) FROM viewing_activity v WHERE v.title_id = t.title_id) AS last_viewed_at
FROM titles t
WHERE t.is_netflix_original
ORDER BY total_views DESC;
```

**R20: Marketing: 10 titles added to the most My Lists in June 2026**
```sql
SELECT m.title_id, t.name, count(*) AS adds
FROM my_list m
JOIN titles t ON t.title_id = m.title_id
WHERE m.added_at >= '2026-06-01' AND m.added_at < '2026-07-01'
GROUP BY m.title_id, t.name
ORDER BY adds DESC
LIMIT 10;
```

**R21: Payments: accounts on hold whose billing date has already passed**
```sql
SELECT account_id, email, next_billing_date
FROM accounts
WHERE status = 'ON_HOLD'
  AND next_billing_date < '2026-07-01'
ORDER BY next_billing_date;
```

**R22: "Last chance to watch" row: licensed titles leaving in July 2026**
```sql
SELECT title_id, name, leaving_on
FROM titles
WHERE leaving_on BETWEEN '2026-07-01' AND '2026-07-31'
ORDER BY leaving_on;
```

**R23: Support console: all viewing activity, newest first, page 6,001 (25 per page)**
```sql
SELECT view_id, profile_id, title_id, episode_id, started_at
FROM viewing_activity
ORDER BY started_at DESC
OFFSET 150000
LIMIT 25;
```

**R24: "Who's watching?" screen: profiles of account 1409**
```sql
SELECT profile_id, profile_name, is_kids, maturity_limit
FROM profiles
WHERE account_id = 1409
ORDER BY created_at;
```

**R25: "More like this": titles sharing at least 2 genres with series 2909**
```sql
SELECT tg2.title_id, count(*) AS shared_genres
FROM title_genres tg1
JOIN title_genres tg2 ON tg2.genre_id = tg1.genre_id AND tg2.title_id <> tg1.title_id
WHERE tg1.title_id = 2909
GROUP BY tg2.title_id
HAVING count(*) >= 2
ORDER BY shared_genres DESC, tg2.title_id
LIMIT 20;
```

**W01: Player: profile 7043 starts episode S1E5 of series 2909**
```sql
INSERT INTO viewing_activity (view_id, profile_id, title_id, episode_id, started_at, duration_watched_sec, device_type, completed)
SELECT 90000001, 7043, 2909, episode_id, '2026-07-01 21:00:00+05:30', 120, 'TV', FALSE
FROM episodes WHERE title_id = 2909 AND season_no = 1 AND episode_no = 5;
```

**W02: "+ My List": profile 7043 adds series 2523**
```sql
INSERT INTO my_list (profile_id, title_id, added_at)
VALUES (7043, 2523, '2026-07-01 21:05:00+05:30')
ON CONFLICT (profile_id, title_id) DO NOTHING;
```

**W03: Account settings: account 1409 downgrades to the STANDARD plan**
```sql
UPDATE accounts
SET plan_id = (SELECT plan_id FROM plans WHERE plan_name = 'STANDARD')
WHERE account_id = 1409;
```

**W04: Monthly billing run: create July 2026 invoices for every active account**
```sql
INSERT INTO invoices (invoice_id, account_id, billing_period_start, amount_inr, status, paid_at)
SELECT 90000000 + a.account_id, a.account_id, DATE '2026-07-01', p.monthly_price_inr, 'PAID',
       TIMESTAMPTZ '2026-07-01 06:00:00+05:30'
FROM accounts a
JOIN plans p ON p.plan_id = a.plan_id
WHERE a.status = 'ACTIVE';
```

**W05: Dunning: put active accounts whose latest invoice failed on hold**
```sql
UPDATE accounts a
SET status = 'ON_HOLD'
WHERE a.status = 'ACTIVE'
  AND EXISTS (SELECT 1 FROM invoices i
              WHERE i.account_id = a.account_id
                AND i.billing_period_start = '2026-06-01'
                AND i.status = 'FAILED');
```
