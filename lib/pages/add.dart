import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:klang/constants/regex.dart';
import 'package:klang/constants/transpiled_constants.dart';
import 'package:klang/http_helper.dart';
import 'package:klang/main.dart';
import 'package:klang/page_router.dart';
import 'package:klang/pages/klang_page.dart';
import 'package:klang/presets.dart';

class AddPage extends StatefulWidget implements KlangPage {
  final _formKey = GlobalKey<FormState>();
  final _tagKey = GlobalKey<FormFieldState>();
  @override
  PageRoutePath get route => PageRoutePath.main("/add");

  @override
  State<StatefulWidget> createState() {
    return _AddPageState();
  }
}

class _AddPageState extends State<AddPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final Set<String> _tags = Set();
  SelectedAudioFile _selectedAudioFile;
  bool _explicit = false;
  bool _forAddTag = false;

  void _resetForm() {
    setState(() {
      _nameController.clear();
      _tagController.clear();
      _descController.clear();
      _urlController.clear();
      _tags.clear();
      _selectedAudioFile = null;
      _explicit = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget._formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KlangTextFormField(
              "sound name",
              controller: _nameController,
              validator: (name) {
                if (name.length <= 0) {
                  return "please name your sound";
                }
                if (name.length < Lengths.min_sound_name_length) {
                  return "too short, min sound name length is ${Lengths.min_sound_name_length} characters";
                }
                if (name.length > Lengths.max_sound_name_length) {
                  return "too long, max sound name length is ${Lengths.max_sound_name_length} characters";
                }
                return null;
              },
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: KlangTextFormField(
                    "add tag",
                    key: widget._tagKey,
                    controller: _tagController,
                    validator: (tag) {
                      if (!_forAddTag) return null;
                      if (tag.length <= 0) {
                        return null;
                      }
                      if (_tags.length >= Lengths.max_sound_tags) {
                        return "sounds may only have up to 3 tags";
                      }
                      if (KlangRegex.tag_banished_chars.hasMatch(tag)) {
                        return "tags may only contain letters (A-Z), numbers (0-9), and spaces";
                      }
                      if (tag.length < Lengths.min_tag_length) {
                        return "too short, min tag length is ${Lengths.min_tag_length} characters";
                      }
                      if (tag.length > Lengths.max_tag_length) {
                        return "too long, max tag length is ${Lengths.max_tag_length} characters";
                      }

                      return null;
                    },
                    trailing: IconButton(
                      icon: Icon(Icons.cancel),
                      onPressed: () {
                        _tagController.clear();
                      },
                    ),
                  ),
                ),
                KlangFormButtonPrimary(
                  "add tag",
                  onPressed: () {
                    _forAddTag = true;
                    if (!widget._tagKey.currentState.validate()) return;
                    if (_tagController.text.length <= 0) return;

                    setState(() {
                      _tags.add(_tagController.text);
                      _tagController.clear();
                    });
                  },
                ),
              ],
            ),
            // sound tags are displayed / removed here
            Wrap(
              alignment: WrapAlignment.start,
              direction: Axis.horizontal,
              runSpacing: 8,
              spacing: 8,
              children: _buildTags(),
            ),
            KlangTextFormField(
              "sound description",
              controller: _descController,
              validator: (desc) {
                if (desc.length <= 0) {
                  return null;
                }
                if (desc.length < Lengths.min_sound_name_length) {
                  return "too short, min description length is ${Lengths.min_description_length} characters";
                }
                if (desc.length > Lengths.max_sound_name_length) {
                  return "too long, max description length is ${Lengths.max_description_length} characters";
                }
                return null;
              },
            ),
            KlangTextFormField(
              "source url",
              controller: _urlController,
              validator: (url) {
                if (url.length <= 0) {
                  return null;
                }
                if (!(Uri.tryParse(url)?.hasAbsolutePath ?? false)) {
                  return "invalid url, may be missing \"https://\". Example url: \"https://www.google.com\", or \"https://shmibblez.com\"";
                }
                return null;
              },
            ),
            KlangFormButtonPrimary(
              _selectedAudioFile == null
                  ? "select audio file"
                  : "audio file selected",
              onPressed: _selectAudioFile,
            ),
            if (_selectedAudioFile != null)
              FutureBuilder(
                future: _selectedAudioFile.duration,
                builder: (_, AsyncSnapshot<Duration> snap) {
                  switch (snap.connectionState) {
                    case ConnectionState.done:
                      return Padding(
                        padding: KlangPadding.formFieldPadding,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("file info"),
                            Text("name: ${_selectedAudioFile.name}"),
                            Text("size: ${_selectedAudioFile.sizeStr}"),
                            Text(snap.data?.inSeconds == null
                                ? "duration: unknown"
                                : "duration: ${snap.data?.inSeconds}")
                          ],
                        ),
                      );
                    default:
                      return Offstage(offstage: true);
                  }
                },
              ),
            Padding(
              padding: KlangPadding.formFieldPadding,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("is this sound or sound name explicit?"),
                  Checkbox(
                    value: _explicit,
                    onChanged: (checked) {
                      if (_explicit == checked) return;
                      setState(() {
                        _explicit = checked;
                      });
                    },
                  ),
                ],
              ),
            ),
            KlangFormButtonPrimary(
              "upload",
              onPressed: _onSubmit,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTags() {
    final List<Widget> tagChips = [];
    for (String t in _tags) {
      tagChips.add(InputChip(
        label: Text(t),
        onDeleted: () {
          setState(() {
            _tags.removeWhere((element) => element == t);
          });
        },
      ));
    }
    return tagChips;
  }

  void _selectAudioFile() async {
    FilePickerResult r = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
      allowedExtensions: ["mp3", "m4a", "flac", "aac"],
    );
    debugPrint("audio file selected");
    if (r == null || r.files.isEmpty) return;
    PlatformFile file = r.files.first;
    SelectedAudioFile sound = SelectedAudioFile(file);

    // if something wrong, show error, return, & don't update file
    String notOkMessage = await sound.getNotOkMessage();
    if (notOkMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(ErrorSnackbar(notOkMessage));
      return;
    }

    // if all good update selected file
    setState(() {
      _selectedAudioFile = SelectedAudioFile(file);
    });
  }

  void _onSubmit() async {
    _forAddTag = false;
    if (!widget._formKey.currentState.validate()) return;
    if (_selectedAudioFile == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(ErrorSnackbar("no audio file selected"));
      return;
    }
    if (!_selectedAudioFile.isOk) {
      debugPrint("file not ok");
      return;
    }
    if (!(await _selectedAudioFile.isDurationOk)) {
      debugPrint("file duration not ok");
      return;
    }

    final String uid = BlocProvider.of<AuthCubit>(context).uid;
    if (uid == null) {
      debugPrint("uid is null");
      return;
    }

    BlocProvider.of<TouchEnabledCubit>(context).disableTouch();

    CreateSoundResult r = await FirePP.create_sound(
      name: _nameController.text,
      tags: _tags,
      description: _descController.text,
      url: _urlController.text,
      explicit: _explicit,
      fileBytes: _selectedAudioFile.bytes,
      fileName: _selectedAudioFile.name,
    );

    final msg = FirePP.translateCreateSoundResult(r);
    ScaffoldMessenger.of(context).showSnackBar(
      r == CreateSoundResult.success
          ? SuccessSnackbar(msg)
          : ErrorSnackbar(msg),
    );

    // TODO: not resetting for some reason, just figured out why -> key might change, but values remain, need to reset all values
    // this means can remove _resets and KeyedSubtree parent
    if (r == CreateSoundResult.success) {
      _resetForm();
    }
    BlocProvider.of<TouchEnabledCubit>(context).enableTouch();
  }
}

class SelectedAudioFile {
  SelectedAudioFile(this._f);

  final PlatformFile _f;

  String get name => _f.name;
  int get size => _f.size;
  Uint8List get bytes => _f.bytes;
  Future<Duration> get duration => flutterSoundHelper.duration(
        Uri.dataFromBytes(bytes).toString(),
      );

  String get sizeStr => (size / 1000000).toString() + " MB";

  bool get isSizeOk => this.size < Lengths.max_sound_file_size_bytes;

  bool get isOk => this.isSizeOk;

  Future<String> getNotOkMessage() async {
    if (!isSizeOk) {
      return "file too big, max file size is 1 MB, selected file size is ${size / 1000000.0} MB";
    }
    if (!(await isDurationOk)) {
      return "maximum duration is ${Lengths.max_sound_duration_millis / 1000} seconds, selected file duration is ${(await duration)?.inSeconds} seconds";
    }
    return null;
  }

  Future<bool> get isDurationOk => duration.then(
        (value) =>
            value?.inMilliseconds ?? 0 < Lengths.max_sound_duration_millis,
      );
}
