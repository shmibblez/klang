// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:klang/constants/klang_constants.dart';
import 'package:klang/http_helper.dart';
import 'package:klang/objects/klang_obj.dart';

class KlangSound extends KlangObj {
  KlangSound._({
    this.id,
    this.name,
    this.tags,
    this.description,
    this.source_url,
    this.creator_id,
    this.timestamp_created,
    this.timestamp_updated,
    this.audio_file_bucket,
    this.audio_file_path,
    this.audio_file_duration,
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
  final String creator_id;
  final Timestamp timestamp_created;
  final Timestamp timestamp_updated;
  final String audio_file_bucket;
  final String audio_file_path;
  final double audio_file_duration;
  final bool explicit;
  final int total_downloads;
  final int total_saves;
  final Map<String, dynamic> _metrics;

  // KlangSound.fromJsonObj();
  static KlangSound _fromMap(Map<String, dynamic> map) {
    final created_secs = map[Root.info][Info.timestamp_created]["_seconds"];
    final created_nano = map[Root.info][Info.timestamp_created]["_nanoseconds"];
    final updated_secs = map[Root.info][Info.timestamp_created]["_seconds"];
    final updated_nano = map[Root.info][Info.timestamp_created]["_nanoseconds"];
    // debugPrint("***sound map: $map");
    return KlangSound._(
      id: map[Root.info][Info.id],
      name: map[Root.info][Info.item_name][Info.item_name],
      tags: (map[Root.info][Info.tags] as List<dynamic>)
              .map((e) => e.toString())
              .toList() ??
          List.empty(),
      description: map[Root.info][Info.description] ?? "",
      source_url: map[Root.info][Info.source_url] ?? "",
      creator_id: map[Root.info][Info.creator_id],
      timestamp_created: Timestamp(created_secs, created_nano),
      timestamp_updated: Timestamp(updated_secs, updated_nano),
      audio_file_bucket: map[Root.info][Info.storage][Info.audio_file_bucket],
      audio_file_path: map[Root.info][Info.storage][Info.audio_file_path],
      audio_file_duration: map[Root.info][Info.storage]
          [Info.audio_file_duration],
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

  List<dynamic> getMetricQueryOffset(String metric, String timePeriod) {
    return [
      (_metrics[metric] ?? const {})[timePeriod],
      this.id,
    ];
  }

  List<dynamic> getSKQueryOffset() {
    return [this.id];
  }

  static List<KlangSound> fromJsonArr(List data) {
    List<KlangSound> sounds = [];
    for (final Map<String, dynamic> m in data) {
      sounds.add(KlangSound._fromMap(m));
    }
    return sounds;
  }

  String getDownloadUrl() {
    // TODO: replace slash with "%2F" ?
    if (FirePP.isTesting)
      return "http://localhost:9199/v0/b/klang-7.appspot.com/o/test_sound.aac?alt=media&token=9c1f06d9-aabb-4abd-b667-49ad2ba5dd7f";
    return "https://firebasestorage.googleapis.com/v0/b/$audio_file_bucket/o/$audio_file_path";
  }

  @override
  operator ==(Object o) => o is KlangSound && o.id == this.id;

  @override
  int get hashCode => id.hashCode;
}
