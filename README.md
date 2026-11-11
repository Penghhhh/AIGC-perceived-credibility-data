# AIGC Perceived Credibility — Data, Analysis Code, and Experiment Programs

Data, analysis code, figures, and the experiment programs (the interfaces participants saw) for the manuscript:

> **How detection and disclosure labels influence the perceived credibility of online information: perceived AI authorship and psychological discomfort pathways**

The project studies how **AIGC (AI-generated content) labels** affect the perceived credibility of online information, through two psychological pathways: *perceived AI authorship* (a cognitive attribution) and *label-related psychological discomfort* (an affective response). It comprises two within-person (repeated-measures) web experiments.

## Study 1 — Platform-issued detection label (e-commerce)

Simulated Taobao-like interface; **N = 93 participants** each rated **20 product reviews** (4 reviews × 5 products; 1,860 trial-level observations). On half of the trials the review carried a platform detection label ("Suspected AI-generated content"). The label was randomized within participant and within review.

Key findings: the detection label increased perceived AI authorship, which in turn was associated with lower perceived credibility (indirect effect; the residual direct effect was null). This indirect association was stronger among participants with greater confidence in the platform's AI-detection system (conditional indirect effect / moderated mediation).

Analysis: multilevel moderated mediation with **crossed random effects** for participants and reviews (lme4), inference by two-way cluster bootstrap (B = 5,000).

## Study 2 — Detection × disclosure labels (social media)

Simulated Rednote (Xiaohongshu)-like interface; **N = 149 participants** each rated **4 stimulus posts** in a **2 (detection label) × 2 (disclosure label) fully within-person design** (596 observations; Latin-square assignment of posts to condition cells). Label wordings: "Creator Declaration: The content was created using AI." (disclosure) and "Platform Declaration: The content is suspected AIGC, please verify carefully." (detection).

Key findings: each label alone reduced perceived credibility relative to no label, while presenting both produced little additional decline (subadditivity). The disclosure label increased perceived AI authorship more, whereas the detection label elicited more psychological discomfort. Only the indirect pathway through perceived AI authorship was reliably significant; the discomfort pathway was not.

Analysis: repeated-measures MANOVA / rmANOVA as design-based descriptive tests, plus a two-level dual-mediation SEM (lavaan, MLR) with a single inference engine — participant-level nonparametric bootstrap (B = 5,000, percentile and BCa 95% CIs).

## Repository structure

```
study1/
├── original_data/
│   └── data_study1.xlsx              # original raw export (Study 1)
├── analysis/
│   ├── exp1_data.dat                 # analysis-ready data (no header; see codebook below)
│   ├── analysis_revised.R            # main analysis script (Study 1)
│   ├── analysis_results_revised.txt  # saved output of the main analysis
│   └── Monte Carlo/
│       └── power_analysis_study1.R   # a-priori & post-hoc power (Monte Carlo)
├── figures/
│   ├── procedure_v3.png / .svg            # experimental procedure
│   └── study_1_simple_slopes_v2.png / .svg  # simple slopes of the moderated first stage
└── experiment_program/               # Study 1 experiment program (HTML + Node.js/Express)
    ├── registration.html             # participant registration & pre-measures
    ├── portal.html                   # experiment homepage with five product entries
    ├── experiment1_data.js           # server: products, reviews, randomization, port 5500
    ├── views/goodsinfo.ejs           # product-page template (reviews + rating scales)
    ├── public/                       # server-side assets (styles, scripts, parameter charts)
    ├── css/ js/ images/ source/      # assets for the registration page and homepage
    └── package.json
study2/
├── original_data/
│   └── data_study2.xlsx              # original raw export (Study 2)
├── analysis/
│   ├── exp2_data_with_post.dat       # analysis-ready data (see codebook below)
│   ├── analysis_bootstrap.R          # main analysis script (Study 2)
│   ├── analysis_bootstrap_output.txt  # saved output of the main analysis
│   └── Monte Carlo/
│       └── power_analysis_study2.R   # a-priori & post-hoc power (Monte Carlo)
├── figure/
│   ├── procedure_v5.svg / Study2_procedure_figure.png  # experimental procedure
│   └── study2_manova_3panel_v2.png / .svg              # MANOVA three-panel figure
└── experiment_program/               # Study 2 experiment program (jsPsych 7.3.4)
    ├── index.html                    # interface: homepage of four posts + reading popup
    ├── test.js                       # trial flow, rating scales, random label assignment
    ├── test.css
    └── avatar.png                    # placeholder for a dead avatar link (see notes)
```

## Codebook

### `study1/analysis/exp1_data.dat` (tab-separated, no header, 1,860 rows)

| Column | Variable | Description |
|---|---|---|
| 1 | `participant_id` | Participant (1–93) |
| 2 | `review_id` | Review/stimulus (11–54; first digit = product 1–5, second = review 1–4) |
| 3 | `detection_label` | Platform detection label (0 = absent, 1 = present), balanced within participant |
| 4 | `functional_value` | Perceived functional value of the review (1–7; post-treatment, sensitivity analysis only) |
| 5 | `experiential_value` | Perceived experiential value (1–7; post-treatment, sensitivity analysis only) |
| 6 | `emotional_valence` | Emotional valence (1–7; post-treatment, sensitivity analysis only) |
| 7 | `perceived_ai_authorship` | Perceived likelihood the review was written by AI (1–7; mediator) |
| 8 | `perceived_credibility` | Perceived credibility of the review (1–7; outcome) |
| 9 | `detection_confidence` | Confidence in the platform's AI-detection system (1–7; participant-level, averaged over 5 product blocks) |

### `study2/analysis/exp2_data_with_post.dat` (space-separated, header row, 596 rows)

| Column | Variable | Description |
|---|---|---|
| `id` | participant | Participant (1–149); 4 observations each |
| `detect` | detection label | 0 = absent, 1 = present |
| `disclo` | disclosure label | 0 = absent, 1 = present |
| `AJ` | perceived AI authorship | Mediator M1 (1–7) |
| `PD` | psychological discomfort | Mediator M2 (label-related discomfort, 1–7) |
| `PC` | perceived credibility | Outcome Y (1–7) |
| `post` | stimulus post | Post identity (1–4; within-person factor, Latin-square assigned to conditions) |

## Reproducing the analyses

1. Open the main script for the study you want: `study1/analysis/analysis_revised.R` or `study2/analysis/analysis_bootstrap.R`. Set the working directory to the script's own folder (the scripts read the `.dat` file by relative path).
2. Required R packages: `lme4`, `lavaan`, `dplyr` (Study 1); `lme4`, `lavaan`, `dplyr` (Study 2). Versions used for the archived outputs: **R 4.6.1, lavaan 0.7.2, lme4 2.0.6**.
3. Run the script; it prints all reported statistics to the console. The archived console outputs (`analysis_results_revised.txt`, `analysis_bootstrap_output.txt`) are provided so that every number in the manuscript can be checked without re-running (the bootstrap, B = 5,000, is computationally intensive).
4. Monte Carlo power analyses are in each study's `Monte Carlo/` subfolder.

## Experiment programs

Both studies were run as web pages; the programs under `study1/experiment_program/` and `study2/experiment_program/` are the interfaces participants saw. They contain no participant data.

### Study 1 — `study1/experiment_program/`

Flow: `registration.html` (demographics and pre-measures) → `portal.html` (homepage with five product entries) → a product page opened at `http://localhost:5500/goodsinfo.html?id=1` … `id=5`.

1. Install [Node.js](https://nodejs.org/) (v16 or later).
2. Run `npm install` in `study1/experiment_program/` (only `express` and `ejs`).
3. Run `npm start`; the server listens on port 5500.
4. Open `registration.html` in a browser and follow the flow, or open the product-page URLs above directly.

Notes:

* The product page is the server-rendered template `views/goodsinfo.ejs`, not a static HTML file, which is why the folder contains no product `.html`. `experiment1_data.js` holds the five products, their four reviews each, and the randomization of review order and of the detection label (re-drawn at every server start).
* There is no server-side database: answers are written to the browser's `localStorage`, and the raw data were collected with the CSV export buttons on the registration page ("Download CSV") and on the product page ("Download Data").
* `portal.html` hard-codes `http://localhost:5500/...`; update it if you serve the program on another port.

### Study 2 — `study2/experiment_program/`

Open `index.html` in a browser (internet required: jsPsych 7.3.4, the `survey-likert` and `html-keyboard-response` plugins, and the icon font are loaded from CDNs). Four posts appear in any order; clicking one opens the reading popup, "完成阅读" ("Done reading") reveals the ratings, and submitting marks the post as completed. The four posts receive the four detection × disclosure label combinations in randomized order.

Notes:

* This local build does not transmit data; the data in `study2/original_data/` were collected through a deployed build on the Naodao platform (not included here). The IRB number in the page footer is a placeholder in this version.
* The original avatar image link is dead, so a locally generated placeholder (`avatar.png`) is used; every other external link (product images, logos, icons) is the original link used during data collection and was checked as reachable.

## Notes

- The `original_data/` xlsx files are the raw exports; the `.dat` files are the cleaned, analysis-ready versions actually used by the scripts.
- All experimental stimuli were presented in simulated interfaces; participants gave informed consent, and the studies were conducted in accordance with the relevant ethical guidelines. Ethics approval details are stated in the manuscript.
- The manuscript is currently in preparation/submission; cite the paper (or this repository) when using these materials.

## Third-party materials and disclaimers

The interfaces in `experiment_program/` simulate commercial platforms for research purposes. **They are not affiliated with, endorsed by, or connected to any commercial platform.**

* **Look and feel**: layout, colors, and navigation labels are neutralized mock content, and no platform logo is used anywhere in the repository; any platform name that still appears in the pages occurs only inside the bilingual disclaimer printed on them.
* **Product photos and review texts**: the product gallery images are loaded at runtime from the public CDN links used during data collection and are *not* redistributed by this repository; the review texts are the experimental stimuli described in the manuscript.
* **Self-made assets**: the site logos, avatars, homepage banner, footer badges, sprite icons, and the Study 2 placeholder avatar were generated for this project from plain shapes and text.
* **Parameter charts** (`study1/experiment_program/public/goods/goodsN_parameters.png`) are factual specification tables used as experimental stimuli.
* Every page (registration, homepage, product page, Study 2 index) carries a bilingual disclaimer stating that the interface is a research simulation and that trademarks, images, and texts remain the property of their respective owners.

## License

This repository is released under the [MIT License](LICENSE) — Copyright (c) 2026 Penghhhh. You are free to use, modify, and redistribute the code, data, and figures, provided that the copyright notice and the license text are retained.

The MIT license covers the original code, styles, scripts, and documentation in this repository. Third-party product photographs, review texts, parameter charts, and any trademarks referenced by the simulated interfaces remain the property of their respective owners, are not covered by this license, and are retained only as research stimuli (see above).
