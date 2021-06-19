import {
  Dates,
  Info,
  KlangMetric,
  KlangTimePeriods,
  Metrics,
  Properties,
  Root,
} from "../constants/constants";
import {
  indexName,
  indexProperties,
  indexTags,
  initMetric,
  randomSeeds,
} from "../field_generators";
import { firestore } from "firebase-admin";
import { isMetricStale } from "../field_checks";

export class FirestoreSound {
  // generates initial sound doc data
  static initDocData({
    // obj,
    id,
    name,
    tags,
    description,
    source_url,
    creator_id,
    explicit,
    fileBucket,
    filePath,
    fileDuration,
  }: {
    // obj: functions.storage.ObjectMetadata;
    id: string;
    name: string;
    tags: string[];
    description: string | undefined;
    source_url: string | undefined;
    creator_id: string;
    explicit: boolean;
    fileBucket: string;
    filePath: string;
    fileDuration: number;
  }): { [k: string]: unknown } {
    return {
      [Root.info]: {
        [Info.id]: id,
        [Info.item_name]: {
          [Info.item_name]: name,
          [Info.search_keys]: indexName(name),
          [Info.timestamp_updated]: firestore.FieldValue.serverTimestamp(),
        },
        [Info.tags]: tags,
        [Info.tag_keys]: indexTags(tags),
        [Info.description]: description ?? "",
        [Info.source_url]: source_url ?? "",
        [Info.creator_id]: creator_id,
        [Info.timestamp_created]: firestore.FieldValue.serverTimestamp(),
        [Info.timestamp_updated]: firestore.FieldValue.serverTimestamp(),
        [Info.storage]: {
          [Info.audio_file_bucket]: fileBucket, // obj.bucket,
          [Info.audio_file_path]: filePath, // obj.name,
          [Info.audio_file_duration]: fileDuration,
        },
      },
      [Root.properties]: {
        [Properties.explicit]: explicit,
        [Properties.hidden]: false,
        [Properties.search_keys]: indexProperties(explicit, false),
        [Properties.random_seeds]: randomSeeds(),
      },
      [Root.metrics]: {
        [Metrics.downloads]: initMetric(),
        [Metrics.saves]: initMetric(),
        [Metrics.best]: initMetric(),
        [Metrics.parent_lists]: initMetric(),
      },
      // no metrics when created
      // no legal info when created
    };
  }

  static formatSaveCloneId(sound_id: string, num: number): string {
    return sound_id + "-" + Math.trunc(num);
  }

  static parseSaveCloneId(clone_id: string): string {
    return clone_id.substring(0, clone_id.lastIndexOf("-") - 1);
  }

  /**
   * modifies [data] directly
   * @param metric metric to update
   * @param data doc data to modify/update
   * @param change save count change, can be + or -
   */
  static updateMetric({
    metric,
    data,
    change,
  }: {
    metric: KlangMetric;
    data: { [k: string]: any };
    change: number;
  }): void {
    // update total
    (data[Root.metrics][metric][Metrics.total] as number) += change;
    // for each time period:
    // - if metric count exists, increment - don't overflow (timestamp stale not changed)
    // - if metric count doesn't exist, set - do overflow (timestamp stale is set to next time period end, after closest one)
    for (const tp of KlangTimePeriods) {
      // these metrics don't need stale maintenance
      if (tp === Metrics.total || tp === Metrics.this_day) continue;
      // get current metric count
      const num = data[Root.metrics][metric][tp];
      const tp_stale = Metrics.matchToTimePeriodStale(tp);
      if (num === 0 || isMetricStale(data[Root.metrics][metric][tp_stale])) {
        // if not set or stale, reset count and timestamp stale
        let date_stale = Dates.currentTimePeriodEnd({ tp: tp });
        if (Dates.withinOffsetPeriod({ tp: tp })) {
          // if within offset period, timestamp stale is when next time period ends
          date_stale = Dates.nextTimePeriodEnd({ tp: tp });
        }
        // set timestamp stale
        data[Root.metrics][metric][tp_stale] =
          firestore.Timestamp.fromDate(date_stale);
        // set metric count
        (data[Root.metrics][metric][tp] as number) = change;
      } else {
        // timestamp stale unchanged, only update metric
        (data[Root.metrics][metric][tp] as number) += change;
      }
    }
  }
}
