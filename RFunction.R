library("move2")

## The parameter "data" is reserved for the data object passed on from the previous App

# Helper: per-track summary (number of locations and median time lag in minutes)
summariseTracks <- function(x) {
  ids <- as.character(mt_track_id(x))
  lags <- as.numeric(mt_time_lags(x, units = "min"))
  data.frame(
    track_id = sort(unique(ids)),
    n_locations = as.vector(table(ids)[sort(unique(ids))]),
    median_timelag_min = as.vector(tapply(lags, ids, median, na.rm = TRUE)[sort(unique(ids))]),
    stringsAsFactors = FALSE
  )
}

rFunction <- function(data, interval_value = 1, interval_unit = "hour", ...) {
  allowedUnits <- c("second", "minute", "hour", "day", "week", "month")
  if (is.null(interval_value) || is.na(interval_value) || interval_value < 1) {
    stop("Setting 'interval_value' must be a whole number of 1 or more.")
  }
  if (!interval_unit %in% allowedUnits) {
    stop(paste0("Setting 'interval_unit' must be one of: ", paste(allowedUnits, collapse = ", "), "."))
  }
  interval <- paste(interval_value, interval_unit)

  # mt_filter_per_interval() works on time-ordered tracks
  data <- data[order(mt_track_id(data), mt_time(data)), ]
  before <- summariseTracks(data)
  logger.info(paste0("Input: ", nrow(data), " locations from ", nrow(before), " tracks. Thinning to the first location per ", interval, "."))

  thinned <- mt_filter_per_interval(data, criterion = "first", unit = interval)
  # the first kept location of each track is usually less than one interval from the next one, so it is removed
  thinned <- thinned[duplicated(mt_track_id(thinned)), ]

  # short statistical summary, saved as artefact and written to the log
  after <- if (nrow(thinned) > 0) summariseTracks(thinned) else before[0, ]
  smry <- merge(before, after, by = "track_id", all.x = TRUE, suffixes = c("_before", "_after"))
  smry$n_locations_after[is.na(smry$n_locations_after)] <- 0
  smry$percent_removed <- round(100 * (1 - smry$n_locations_after / smry$n_locations_before), 1)
  lagsBefore <- as.numeric(mt_time_lags(data, units = "min"))
  lagsAfter <- if (nrow(thinned) > 0) as.numeric(mt_time_lags(thinned, units = "min")) else NA
  smry <- rbind(smry, data.frame(
    track_id = "ALL",
    n_locations_before = nrow(data),
    median_timelag_min_before = median(lagsBefore, na.rm = TRUE),
    n_locations_after = nrow(thinned),
    median_timelag_min_after = median(lagsAfter, na.rm = TRUE),
    percent_removed = round(100 * (1 - nrow(thinned) / nrow(data)), 1)
  ))
  smry$median_timelag_min_before <- round(smry$median_timelag_min_before, 2)
  smry$median_timelag_min_after <- round(smry$median_timelag_min_after, 2)
  write.csv(smry, file = appArtifactPath("thinning_summary.csv"), row.names = FALSE)

  logger.info(paste0(
    "Output: ", nrow(thinned), " of ", nrow(data), " locations kept (",
    smry$percent_removed[nrow(smry)], "% removed); ",
    sum(smry$n_locations_after[smry$track_id != "ALL"] > 0), " of ", nrow(before), " tracks kept. ",
    "Median time lag before: ", smry$median_timelag_min_before[nrow(smry)], " min; after: ",
    smry$median_timelag_min_after[nrow(smry)], " min."
  ))

  if (nrow(thinned) == 0) {
    logger.warn("No locations are left after thinning. Returning NULL.")
    return(NULL)
  }
  return(thinned)
}
