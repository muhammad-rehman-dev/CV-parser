# Dental Talent, Candidate Onboarding with CV Upload

A candidate onboarding module for a dental recruitment platform, built with Ruby on Rails. A candidate uploads their CV, the system reads as much profile data as it can in the background, and then the candidate reviews, corrects, and completes the profile before saving it.

## What this product does

Recruitment teams want rich, structured candidate profiles, but candidates do not want to retype everything that is already in their CV. This module bridges that gap in two stages:

1. **Upload the CV.** The candidate drags and drops a PDF, DOC, or DOCX file and accepts the processing consent. The file is stored privately and a background job starts reading it. A friendly progress screen keeps the candidate informed while parsing runs.
2. **Review and complete the profile.** The system opens a prefilled form. Fields taken from the CV are labelled so the candidate knows what came from the file, what looks uncertain and should be double checked, and what is still missing. The candidate fixes anything wrong, fills the gaps, and saves. On save the profile is validated and the recruitment team is notified.

A few principles guide the behaviour:

* The parser never invents data. Anything it cannot find in the CV is left empty rather than guessed.
* Inferred values (such as job function, BIG registration status, or years of experience) are flagged for review instead of being treated as final.
* Parsing is best effort. If it fails or the candidate prefers, they can always continue and fill the form manually.
* Dutch and English CVs are both supported.

## Tech stack

* **Ruby** 3.3.2 and **Rails** 7.2
* **PostgreSQL** for the database, including a `jsonb` column for per field metadata
* **Active Storage** (local disk) for private CV files
* **Solid Queue** for background jobs
* **Devise** for candidate accounts and **ActiveAdmin** for the recruiter and admin area
* **Hotwire** (Turbo and Stimulus) with **Tailwind CSS** for the interface
* **ruby_llm** for CV parsing, using Google Gemini by default, with a local heuristic fallback
* **letter_opener** for previewing outgoing email in development

Node is not required. The project uses importmap for JavaScript and the standalone Tailwind binary for CSS.

## Design patterns and how the code is organised

The codebase leans on a small set of familiar patterns so controllers and models stay slim and each piece is easy to test in isolation.

### Service objects

The CV pipeline and the profile completion logic live in plain Ruby service objects under `app/services`. Each one has a single responsibility and returns a simple result, which keeps controllers focused on request and response handling.

```
app/services/cv/
  text_extractor.rb       reads plain text from a PDF, DOCX, or DOC file
  llm_extractor.rb        turns text into structured JSON using an LLM
  heuristic_extractor.rb  a regex and keyword fallback when no LLM key is set
  parser.rb               orchestrates extraction and returns a ParsedResult
  profile_mapper.rb       maps a ParsedResult onto a profile and nested records
app/services/onboarding/
  profile_completion.rb   finalises the profile on the last step in one transaction
  completion_notifier.rb  sends the email and the optional webhook after completion
```

### Value object

`Cv::ParsedResult` is an immutable value object that carries the extracted data plus its source (LLM, heuristic, or none). It gives the rest of the pipeline one predictable shape to work with.

### Background jobs

Anything slow or external runs off the request cycle:

* `ParseCandidateCvJob` runs the parser and prefills the profile. If it fails, the document is marked failed so the candidate can continue manually.
* `DeliverOnboardingWebhookJob` posts a completion event when a webhook URL is configured.

### Concerns

Shared behaviour is extracted into concerns so it lives in one place:

* `ReferenceData` holds the common scopes and label for the admin managed lookup models.
* `ParsingStatus` holds the document parsing lifecycle (the status enum and its transitions).
* `FieldMetadata` exposes the review badge helpers backed by the `jsonb` metadata column.
* `ConsentVerification` holds the consent check shared by the upload and profile controllers.

These concerns are used across several models or controllers. The completion rule set, by contrast, lives directly in `CandidateProfile` (grouped under a single `with_options on: :complete` block) because it is specific to that one model.

### Custom validator

`SubsetValidator` checks that every value in an array attribute belongs to an allowed set, and is reused for fields such as transport types and available working days.

## Data model

```
User
  has_one CandidateProfile
CandidateProfile
  belongs_to JobFunction
  has_many CandidateDocument
  has_many Education
  has_many WorkExperience
  has_many CandidateSkill    (through to Skill)
  has_many CandidateLanguage (through to Language)
  has_many CandidateRegion, CandidateEmploymentType (join tables)
```

The reference tables (`JobFunction`, `Region`, `EmploymentType`, `Language`, `Skill`) and a `Setting` key and value store are all admin managed, so options can change without a deploy.

## Prerequisites

* Ruby 3.3.2. A `.ruby-version` file is included, so rbenv or rvm will pick it up automatically.
* PostgreSQL running locally.

## Setup

```bash
bundle install
cp .env.example .env        # then fill in GEMINI_API_KEY (see below)
bin/rails db:prepare        # create, migrate, and seed
```

## Running the project

```bash
bin/dev
```

This starts the web server, the Tailwind watcher, and the Solid Queue worker together. The application runs at http://localhost:3000.

Seeded logins for development:

* **Candidate:** `candidate@example.com` with password `password`
* **Admin** (ActiveAdmin at `/admin`): `admin@example.com` with password `password`

## Trying it out with a sample CV

If you want to test the upload and parsing flow without preparing your own file, a sample CV is included. It is the Sophie profile that was used while building and testing the parser:

* `tmp/samples/sophie_cv.pdf`

Sign in as the seeded candidate, start the upload step, and drop that file in. There is also a smaller fixture used by the automated tests at `test/fixtures/files/sample_cv.pdf` if you prefer that one.

## Running the specs

The test suite uses Minitest and covers the conditional validations, the heuristic extractor, the profile mapper (including the no invention rule and skill matching), and the two stage flow plus the admin dashboard through integration tests.

```bash
bin/rails test
```

## CV parsing configuration

Parsing works out of the box in a reduced mode with no API key, using the local heuristic extractor. For high quality extraction, configure an LLM provider in `.env`.

| Variable          | Default              | Notes                                                  |
| ----------------- | -------------------- | ------------------------------------------------------ |
| `CV_LLM_PROVIDER` | `gemini`             | One of `gemini`, `groq`, or `openai`                   |
| `CV_LLM_MODEL`    | `gemini-flash-latest`| Model name for the chosen provider                     |
| `GEMINI_API_KEY`  | (none)               | Free tier keys at https://aistudio.google.com/api-keys |
| `GROQ_API_KEY`    | (none)               | OpenAI compatible, used when set                       |
| `OPENAI_API_KEY`  | (none)               | Optional                                               |

Other settings:

| Variable                           | Default                   | Notes                                                        |
| ---------------------------------- | ------------------------- | ----------------------------------------------------------- |
| `RECRUITMENT_TEAM_EMAIL`           | `recruitment@example.com` | Who receives the completion notification                    |
| `CANDIDATE_ONBOARDING_WEBHOOK_URL` | (none)                    | When set, a completion event is posted to this URL          |

The `.env` file is gitignored. Never commit real keys. If a key is ever exposed, rotate it.

## Emails

In development, outgoing mail is handled by letter_opener. Each email, such as the recruitment team notification, opens automatically in a new browser tab instead of being delivered. The background worker must be running for mail queued with `deliver_later`.

## Admin and configuration management

ActiveAdmin at `/admin` lets recruiters view completed candidate profiles, including a private CV download, and manage the reference data that drives the form: job functions, regions, employment types, languages, and skills. It also exposes the setting for the maximum CV upload size. Changes take effect immediately without a deploy.

## Privacy and security

* CVs are stored privately through Active Storage and are only served through authenticated controllers, either the owning candidate or an admin.
* A consent checkbox is required before uploading and again before saving the profile.
* Raw LLM output is never shown to candidates. Only the mapped fields are persisted.
