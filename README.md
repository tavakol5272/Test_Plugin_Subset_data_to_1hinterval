# Fixed Interval Track Sampling

MoveApps

Github repository: https://github.com/tavakol5272/Test_Plugin_Subset_data_to_1hinterval

## Description
Thins (subsamples) each track to one location per user-defined time interval (default: 1 hour), keeping the first location of each interval, and provides a short statistical summary of how many locations were removed and how the time lag between locations changed.

## Documentation
This App reduces the sampling rate of tracking data to a fixed time interval, e.g. to make tracks with different or irregular fix rates comparable, or to reduce the size of high-resolution data before further analysis.

The App performs the following steps:

1. The data are ordered by track and timestamp.
2. Time is divided into consecutive intervals of the selected length (e.g. 1 hour). Within each track, only the first location in each interval is kept; all other locations are removed.
3. The first remaining location of each track is removed. This location is usually less than one interval away from the next one, because a track rarely starts exactly at the beginning of an interval. After this step, the remaining locations are approximately one interval apart, as far as the original fix rate allows.
4. A short statistical summary is written to the log and saved as a csv artefact (see [Artefacts](#artefacts)).

The intervals are aligned to the calendar/clock in UTC (e.g. with 1 hour, intervals start at full hours), not to the first location of each track.

### Application scope
#### Generality of App usability
This App was developed using GPS data of vultures, but it can be used for tracking data of any taxonomic group.

#### Required data properties
The App should work for any kind of location data with timestamps.

Thinning only has an effect if the fix rate of the data is higher than the selected interval. If the fix rate is lower, no locations are removed except the first location of each track.

It is recommended to remove empty locations and duplicated timestamps before using this App, because the App keeps the first location of each interval in time order.

### Input type
`move2::move2_loc`

### Output type
`move2::move2_loc`

### Artefacts
`thinning_summary.csv`: csv file with a short statistical summary of the thinning, with one row per track and a final row `ALL` for the whole data set. Columns:

- `track_id`: track identifier (`ALL` for the whole data set).
- `n_locations_before`: number of locations in the input data.
- `median_timelag_min_before`: median time lag between consecutive locations in the input data, in minutes.
- `n_locations_after`: number of locations in the output data.
- `median_timelag_min_after`: median time lag between consecutive locations in the output data, in minutes. `NA` if fewer than two locations remain.
- `percent_removed`: percentage of locations removed by the App.

### Settings
`Interval length` (interval_value): Length of the time interval to which the data are thinned. Must be a whole number of 1 or more. Unit: as selected in `Interval unit`. Default: `1`.

`Interval unit` (interval_unit): Unit of the time interval. Options: `Second(s)`, `Minute(s)`, `Hour(s)`, `Day(s)`, `Week(s)`, `Month(s)`. Default: `Hour(s)`.

### Changes in output data
The App filters the input data: only the first location per selected time interval is kept for each track, and the first remaining location of each track is removed. No columns are added, removed or changed. The output data are ordered by track and timestamp. Tracks that end up with no locations are not part of the output.

### Errors and null handling
**Setting `interval_value`:** If the value is missing or smaller than 1, the App stops with an error message.

**Setting `interval_unit`:** If the value is not one of the listed options, the App stops with an error message.

**Tracks with few locations:** Because the first remaining location of each track is removed, a track that has only one location left after thinning is removed completely. The number of tracks kept is reported in the log and can be seen in `thinning_summary.csv` (`n_locations_after` = 0).

**Empty result:** If no locations are left after thinning, the App writes a warning to the log and returns `NULL`. The artefact `thinning_summary.csv` is still created.

### Technical details
- The thinning is done with `move2::mt_filter_per_interval()` using `criterion = "first"` and `unit = "<Interval length> <Interval unit>"` (e.g. `"1 hour"`). The intervals are calculated internally with `lubridate::floor_date()`, so they are aligned to the calendar/clock in UTC.
- Time lags for the summary are calculated with `move2::mt_time_lags()` per track.
- The data are processed per track; all tracks are handled in one call on the whole data set.
- Package used: `move2` (Kranstauber, B., Safi, K., Scharf, A.K. 2024. move2: R package for processing movement data. Methods in Ecology and Evolution. https://doi.org/10.1111/2041-210X.14383).
