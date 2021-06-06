// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:klang/constants/klang_constants.dart';
import 'package:klang/objects/klang_obj.dart';

class KlangUser implements KlangObj {
  KlangUser._({
    this.id,
    this.name,
    this.tags,
    this.description,
    this.source_url,
    this.timestamp_created,
    this.timestamp_updated,
    this.audio_file_bucket,
    this.audio_file_path,
    this.timestamp_deleted,
    this.explicit,
    this.total_downloads,
    this.total_saves,
    metrics,
  }) : this._metrics = metrics;

  final String id;
  final String name;
  final List<String> tags;
  final String description;
  final String source_url;
  final Timestamp timestamp_created;
  final Timestamp timestamp_updated;
  final String audio_file_bucket;
  final String audio_file_path;
  final Timestamp timestamp_deleted;
  final bool explicit;
  final int total_downloads;
  final int total_saves;
  // ignore: unused_field
  final Map<String, dynamic> _metrics;

  static List<KlangUser> fromJsonArr(List data) {
    List<KlangUser> sounds = [];
    for (final Map<String, dynamic> m in data) {
      sounds.add(KlangUser._fromMap(m));
    }
    return sounds;
  }

  // KlangSound.fromJsonObj();
  static KlangUser _fromMap(Map<String, dynamic> map) {
    final created_secs = map[Root.info][Info.timestamp_created]["_seconds"];
    final created_nano = map[Root.info][Info.timestamp_created]["_nanoseconds"];
    final updated_secs = map[Root.info][Info.timestamp_created]["_seconds"];
    final updated_nano = map[Root.info][Info.timestamp_created]["_nanoseconds"];
    final deleted_secs =
        ((map[Root.deleted] ?? const {})[Deleted.timestamp_deleted] ??
            const {})["_seconds"];
    final deleted_nano =
        ((map[Root.deleted] ?? const {})[Deleted.timestamp_deleted] ??
            const {})["_nanoseconds"];
    // debugPrint("***sound map: $map");
    return KlangUser._(
      id: map[Root.info][Info.id],
      name: map[Root.info][Info.item_name][Info.item_name],
      tags: (map[Root.info][Info.tags] as List<dynamic> ?? [])
          .map((e) => e.toString())
          .toList(),
      description: map[Root.info][Info.description] ?? "",
      source_url: map[Root.info][Info.source_url] ?? "",
      timestamp_created: Timestamp(created_secs, created_nano),
      timestamp_updated: Timestamp(updated_secs, updated_nano),
      audio_file_bucket: map[Root.info][Info.storage][Info.audio_file_bucket],
      audio_file_path: map[Root.info][Info.storage][Info.audio_file_path],
      timestamp_deleted:
          deleted_secs != null ? Timestamp(deleted_secs, deleted_nano) : null,
      explicit: map[Root.properties][Properties.explicit],
      total_downloads: ((map[Root.metrics] ?? const {})[Metrics.downloads] ??
              const {})[Metrics.total] ??
          0,
      total_saves: ((map[Root.metrics] ?? const {})[Metrics.saves] ??
              const {})[Metrics.total] ??
          0,
      metrics: map[Root.metrics] ?? {},
    );
  }

  List<dynamic> getSKQueryOffset() {
    return [this.id];
  }
}
