# Capstone Example Project
This template repository is a **starting point** for an end-to-end analytics engineering project in dbt. A completed capstone project is required for the dbt Labs Analytics Engineering for Students learning path. This repo uses the legendary [Jaffle Shop](https://github.com/dbt-labs/jaffle-shop) project for its curated sample data, but with a smaller scope: **only seeds + staging** are included so you can design and build your own intermediate and mart layer.

## What you’re building
By the end of the capstone, you should have:
- A specific, relevant analytics question (or small set) stated up front; perhaps opting for 1 primary, 2–4 supporting questions
- A dbt project that runs end-to-end on **BigQuery**
- At least one **`dim_*`** and/or **`fct_*`** model that clearly answers the stated question(s)
- 2–4 tests (at minimum `not_null` and `unique` on primary keys, plus one business-logic test)
- Descriptions for key models and columns so someone new can easily follow the work
- A short write-up in the README, with at least one insight stated and supported by data evidence and at least one realistic next step that follows from the insight(s). Include sections that say `Insights: ` and `Next Steps: `.

---

## Prerequisites
- BigQuery project + dataset you can write to
- dbt (Fusion + VS Code extension) installed and working
- Git installed and a GitHub account
- A working BigQuery connection configured in `profiles.yml`

---

## Quickstart

### 1) Create a repo from this template
Follow [these instructions](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template#creating-a-repository-from-a-template) to create your own repo from this template.

### 2) Clone that repo locally using VS Code
Follow [these instructions](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo#cloning-your-forked-repository) to clone your repo for local development in VS Code.
```
git clone <YOUR_REPO_URL>
cd <YOUR_REPO_NAME>
```

### 3) Confirm your dbt profile name matches `dbt_project.yml` (important)
This project’s `dbt_project.yml` includes a `profile:` value (for example, `default`). **That value must match the profile name you have configured for BigQuery dev credentials in your `profiles.yml`.**

- If your `dbt_project.yml` says `profile: default`, then your `profiles.yml` must have a top-level profile named `default:`. In this template repo, the `dbt_project.yml` says `profile: capstone_template`, so make sure you have a top-level profile named `capstone_template` in your `profiles.yml` file.

Typical locations:
- In the hidden `.dbt` folder: `~/.dbt/profiles.yml`
- If you are using a repo-local profile (optional): `./profiles.yml`, make sure it is gitignored, otherwise your credentials will be made public!

If the names do not match, dbt will fail with a “profile not found” style error.

### 4) Seed the curated source data (raw layer)
This starter uses dbt **seeds** as the “raw” tables for the project.

Run: `dbt seed`
Alternatively: `dbt build`

This will create the staging models (and run any included tests, if present) alongside using the seeds as sources.

---

## Project structure (starter scope)
You have:
- `seeds/`  
  Curated CSVs that dbt loads into your warehouse (commonly into a `raw` schema or dataset).
- `models/staging/`  
  Staging models that clean and standardize the seeded raw tables.

You do **not** have marts in this repo. You will create them based on the question you have chosen to answer.

Recommended build-out:
- `models/intermediate/` for reshaping, reusable transformations, and business logic
- `models/marts/` for business-facing `dim_*` and `fct_*` models used to answer analytics questions

---

## BigQuery notes (common gotchas)
- Make sure your BigQuery credential (typically the locally saved JSON file) has permission to:
  - create tables/views
  - create and write to datasets
  It is easiest to just give the service account `Owner` permissions
- Be explicit about your target dataset (schema) in `profiles.yml` so you can easily find your outputs.
- If you switch GCP projects or datasets, rerun `dbt debug` to confirm everything is wired correctly.

Useful commands:
```
dbt debug
dbt parse
dbt compile
dbt ls
```

---

## Capstone requirements checklist (use this to self-review)
- [ ] Defined primary + supporting analytics questions
- [ ] Built at least one `dim_*` and/or `fct_*` model
- [ ] Added schema tests for keys (unique, not_null)
- [ ] Added at least one “business logic” test (accepted values, or custom test)
- [ ] Added descriptions to key models and columns
- [ ] Documented metric definitions and entity grain (especially facts)
- [ ] Ran `dbt build` successfully with a clean output
- [ ] README includes: At least one insight stated and supported by data evidence (numbers, comparison, trend, segment, etc.) and at least one realistic next step that follows from the insight(s)

---

## Suggested workflow (ADLC)
1. **Plan**
   - Write questions, entities, grain, and expected outputs
   - You can place these in a top-level `plan.md` file in your project
2. **Develop**
   - Add marts (and, optionally, intermediate) models with clear naming and layering
3. **Test**
   - Add tests early, document decisions
4. **Deploy**
   - Ensure everything builds end-to-end locally and push changes to `main`
5. **Operate**
   - Schedule your project to run via a job (optionally, schedule it) on dbt Platform
6. **Observe**
   - Check lineage and data quality signals via test results
7. **Discover**
   - Add any useful descriptions and documentation to the project, models, and columns.
8. **Analyze**
   - Query your marts (or build an output artifact) and write 1–2 insights plus next steps

---

## How to submit
In the learning path, you will be asked to submit:
- A link to your GitHub repo

The GitHub project README should be updated with:
  - the question(s) you answered
  - how to reproduce your run (what commands are needed)
  - 1–2 insights, backed by model outputs, and next steps

Bonus: You may choose to also submit links to a dashboard (can be screenshots), SQL queries in BigQuery, or a Python notebook that tells the story.
