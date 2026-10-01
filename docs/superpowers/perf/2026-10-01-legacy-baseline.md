# Legacy Baseline — 2026-10-01

Reference numbers for the pre-rewrite app. Every later sub-project reports
against these. Source: `flutter test --run-skipped --tags legacy-bench test/bench`
(desktop, Dart VM JIT) and `tool/device/profile_run.sh legacy_game_perf` (device, profile).

## Desktop (Mac, Dart VM JIT)

| Benchmark | p50 | p95 | max | samples |
|---|---|---|---|---|
| legacy.movegen.all_rolls | 20.1 us | 472.6 us | 1239.4 us | 500 |
| legacy.movegen.doubles | 149.3 us | 1012.3 us | 1302.1 us | 300 |
| legacy.ai.easy.selectTurn | 33.4 us | 542.8 us | 1371.2 us | 200 |
| legacy.ai.medium.selectTurn | 26116227.3 us (26.1 s) | 31293347.6 us (31.3 s) | 31293347.6 us (31.3 s) | 2 |

Raw data: `build/bench/legacy_baseline.json` (not committed).

## Device (Galaxy S, profile) — legacy_game_easy

**PENDING (no Android device connected; run `tool/device/profile_run.sh legacy_game_perf` with the Galaxy S attached; also needs >= 15 GB free disk)**

| Metric | Value |
|---|---|
| average_frame_build_time_millis | PENDING (no device) |
| 90th_percentile_frame_build_time_millis | PENDING (no device) |
| 99th_percentile_frame_build_time_millis | PENDING (no device) |
| average_frame_rasterizer_time_millis | PENDING (no device) |
| 99th_percentile_frame_rasterizer_time_millis | PENDING (no device) |
| missed_frame_build_budget_count | PENDING (no device) |
| missed_frame_rasterizer_budget_count | PENDING (no device) |
| frame_count | PENDING (no device) |

## Reading this report

Desktop numbers are Dart VM JIT on an Apple Silicon Mac; phones are typically
several times slower. The medium bot runs on the UI thread, so the app is
frozen for the whole time it thinks (about 26 s p50 and 31 s max on desktop,
and likely longer on a phone).

## Targets (spec §3.3)
Medium bot ≤ 80 ms p95 (off UI isolate), legal-play generation ≤ 2 ms p95,
≥ 99 % frames within budget on the Galaxy S.
