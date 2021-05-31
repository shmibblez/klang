// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:klang/constants/klang_constants.dart';

class KlangSound {
  KlangSound._({
    this.name,
    this.tags,
    this.description,
    this.source_url,
    this.creator_id,
    this.timestamp_created,
    this.timestamp_updated,
    this.audio_file_bucket,
    this.audio_file_path,
    this.explicit,
    this.total_downloads,
    this.total_saves,
  });

  final String name;
  final List<String> tags;
  final String description;
  final String source_url;
  final String creator_id;
  final Timestamp timestamp_created;
  final Timestamp timestamp_updated;
  final String audio_file_bucket;
  final String audio_file_path;
  final bool explicit;
  final int total_downloads;
  final int total_saves;

  // KlangSound.fromJsonObj();
  static KlangSound _fromMap(Map<String, dynamic> map) {
    final created_secs = map[Root.info][Info.timestamp_created]["_seconds"];
    final created_nano = map[Root.info][Info.timestamp_created]["_nanoseconds"];
    final updated_secs = map[Root.info][Info.timestamp_created]["_seconds"];
    final updated_nano = map[Root.info][Info.timestamp_created]["_nanoseconds"];
    return KlangSound._(
      name: map[Root.info][Info.item_name],
      tags: map[Root.info][Info.tags] ?? List.empty(),
      description: map[Root.info][Info.description],
      source_url: map[Root.info][Info.source_url],
      creator_id: map[Root.info][Info.creator_id],
      timestamp_created: Timestamp(created_secs, created_nano),
      timestamp_updated: Timestamp(updated_secs, updated_nano),
      audio_file_bucket: map[Root.info][Info.storage][Info.audio_file_bucket],
      audio_file_path: map[Root.info][Info.storage][Info.audio_file_path],
      explicit: map[Root.properties][Properties.explicit],
      total_downloads: map[Root.metrics][Metrics.downloads][Metrics.total],
      total_saves: map[Root.metrics][Metrics.saves][Metrics.total],
    );
  }

  static List<KlangSound> fromJsonArr(List data) {
    List<KlangSound> sounds = [];

    for (final Map<String, dynamic> m in data) {
      sounds.add(KlangSound._fromMap(m));
    }

    return sounds;
  }
}
