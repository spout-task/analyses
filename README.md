# SPOUT · analyses

MATLAB preprocessing and plotting scripts for **SPOUT** session data — part of the
[spout-task](https://github.com/spout-task) project. Split by system.

| Folder | Contents |
|---|---|
| [`SPOUT1/`](SPOUT1/) | One-spout preprocessing (`func_get_Arduino_oneSpout_*.m`), a Pavlovian batch, and daily-session plotting |
| [`SPOUT2/`](SPOUT2/) | Two-spout preprocessing (`func_get_Arduino_twoSpouts_*.m`), sync handling, an LL/LR batch, and plotting |

Each `func_get_*` script parses one level of the session output; the
`universal_*_preprocessing_batch.m` scripts run the full pipeline over a set of sessions;
the `plot_*` scripts make daily-session figures.

Inputs are the CSV files produced by [software](https://github.com/spout-task/software); a ready-to-use example
session per system is in the [example_data](https://github.com/spout-task/example_data) repository.

Requirements: **MATLAB** (tested on R2024b and R2026a). No additional toolboxes required.

## Related repositories
[hardware](https://github.com/spout-task/hardware) · [software](https://github.com/spout-task/software) · [settings](https://github.com/spout-task/settings) · [example_data](https://github.com/spout-task/example_data)

## License
**GPL-3.0-or-later** ([`LICENSE`](LICENSE)). See also [`CITATION.cff`](CITATION.cff).
