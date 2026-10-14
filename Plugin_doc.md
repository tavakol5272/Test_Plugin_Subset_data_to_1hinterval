I'll turn your script into a MoveApps App. Before I write any App files, I need you to agree on the plan, because a few choices change what the App does.

## What your script does

Your script reads one file per vulture and runs these steps in order:

1. **Thinning:** keeps the first location in each hour, then drops the first point. For that it uses `mt_filter_per_interval(..., criterion = "first", unit = "hour")`.
2. **Checking speeds:** collects all speeds and draws histograms and quantiles, so you can pick a speed limit by eye.
3. **Speed outliers:** keeps removing points while any speed is above 20 m/s.
4. **Checking distances:** draws histograms and quantiles of the distances, so you can pick a distance limit.
5. **Distance outliers:** removes points with a distance above 1,000,000 m (1000 km). This runs only once.

## My suggestion: make two Apps

Thinning and outlier removal do different jobs, and people often want one without the other. In MoveApps, each App is one step in a Workflow, so two small Apps are easier to reuse.

| | **App A – thin to an hourly interval** | **App B – remove speed and distance outliers** |
|---|---|---|
| Your code | Step 1 | Steps 3 and 5 (steps 2 and 4 could become optional plots) |
| Input | `move2` object (`move2::move2_loc`) | `move2` object (`move2::move2_loc`) |
| Output | Same type, fewer locations | Same type, outliers removed |
| Possible settings | Time unit (hour, day, …) and whether to drop each animal's first point | Maximum speed (m/s) and maximum distance (m) |
| Artefacts (extra output files) | None | Optional: histogram PDF or quantile table of speeds and distances |
| Packages | `move2`, `dplyr` | `move2`, `units`, `dplyr`, maybe `ggplot2` |
| How they connect | Runs first | Runs after App A |

Note that MoveApps may already have Apps for thinning and for speed filtering. Once you pick an App, I'll check the full MoveApps App list and tell you if one already does the same job.

## Things in the code that need fixing first

1. **Folders and file loops:** In MoveApps the App gets **all animals together** in one `data` object and returns it. It does not read or write `.rds` files. So the `readRDS`/`saveRDS` lines, the `lapply` loops and the `genPath` paths will be removed.
2. **`vultr_thinned[-1, ]` removes only one row in total.** That was fine when each file held one animal. With all animals together, it would drop only the first animal's first point. I'd change it to drop the **first point of each animal**: `group_by(mt_track_id()) |> slice(-1)`.
3. **The histograms and quantiles are manual checks**, so the App can't run them interactively. They can be dropped, or saved as an optional PDF/CSV for the user to look at.
4. **The speed filter removes the point *before* a big jump.** `mt_speed()` measures speed from a point to the *next* point. So when a speed is too high, the point that gets removed is the one before the jump, not always the bad point. I'll keep this behaviour unless you say otherwise. Just check this is what you meant.
5. **The distance filter runs only once, but the speed filter repeats.** Removing one point creates a new distance between its neighbours, and that new distance is never checked. Should the distance filter repeat like the speed filter?
6. **Units mix-up in a comment:** the comment says "1000K km", but `maxdist <- 1000000` is in metres, which is **1000 km**. I'll use metres in the App.
7. **The App will expect clean data.** Your input folder name (`clean_empty_duply`) suggests empty and duplicate locations were already removed. The App will expect the same, and I'll say so in the README. The App will also return `NULL` if no locations are left after filtering.
8. **The species and reference-table filtering is not part of the App.** In MoveApps the user picks the data before the App runs.

## Questions for you

1. **What do you want the App to do?** Is my description above right?
2. **One App or two?** If two, which one should I build first, App A or App B? (The other can be done in a separate conversion.)
3. **Settings:** should the user be able to change the limits (20 m/s, 1000 km, and the time unit), with your values as defaults?
4. **Distance filter:** should it run once, as now, or repeat like the speed filter?
5. **Plots:** for App B, do you want the speed and distance histograms as an optional output file?
6. **Name:** do you already have a name in mind? If not, I'll suggest 2–3 names after checking the existing Apps.
