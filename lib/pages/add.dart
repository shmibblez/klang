import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klang/constants/regex.dart';
import 'package:klang/constants/transpiled_constants.dart';
import 'package:klang/http_helper.dart';
import 'package:klang/main.dart';
import 'package:klang/page_router.dart';
import 'package:klang/pages/klang_page.dart';
import 'package:klang/presets.dart';

class AddPage extends StatefulWidget implements KlangPage {
  @override
  PageRoutePath get route => PageRoutePath.main("/add");

  @override
  State<StatefulWidget> createState() {
    return _AddPageState();
  }
}

class _AddPageState extends State<AddPage> {
  final _formKey = GlobalKey<FormState>();
  final _tagKey = GlobalKey<FormFieldState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final List<String> _tags = [];
  SelectedAudioFile _selectedAudioFile;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KlangTextFormField(
              "sound name",
              key: _tagKey,
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
              trailing: IconButton(
                icon: Icon(Icons.cancel),
                onPressed: () {
                  _nameController.clear();
                },
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: KlangTextFormField(
                    "sound description",
                    controller: _tagController,
                    validator: (tag) {
                      if (tag.length <= 0) {
                        return null;
                      }
                      if (KlangRegex.tag_banished_chars.hasMatch(tag)) {
                        return "tags may only contain (A-Z), underscores, dashes, and spaces";
                      }
                      if (tag.length < Lengths.min_tag_length) {
                        return "too short, min tag length is ${Lengths.min_tag_length} characters";
                      }
                      if (tag.length > Lengths.max_tag_length) {
                        return "too long, max tag length is ${Lengths.max_tag_length} characters";
                      }
                      if (_tags.length >= Lengths.max_sound_tags) {
                        return "sounds may only have up to 3 tags";
                      }
                      return null;
                    },
                  ),
                ),
                KlangFormButtonPrimary(
                  "add tag",
                  onPressed: () {
                    // invalid tag, return
                    if (!_tagKey.currentState.validate()) return;
                    _tags.add(_tagController.text);
                  },
                ),
              ],
            ),
            // sound tags are displayed / removed here
            Wrap(
              alignment: WrapAlignment.spaceBetween,
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

            KlangFormButtonSecondary(
              "select audio file",
              onPressed: _selectAudioFile,
            ),
            KlangFormButtonPrimary(
              "add sound",
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
    return [];
  }

  void _selectAudioFile() async {
    FilePickerResult r = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
      allowedExtensions: ["mp3", "m4a", "flac", "aac"],
    );
    if (r.files.isEmpty) return;
    PlatformFile file = r.files.first;
    SelectedAudioFile sound = SelectedAudioFile(file);

    // if something wrong, show error, return, & don't update file
    String notOkMessage = sound.getNotOkMessage();
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
    if (!_formKey.currentState.validate()) return;
    if (_selectedAudioFile == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(ErrorSnackbar("no audio file selected"));
      return;
    }
    if (!_selectedAudioFile.isOk) return;

    final String uid = BlocProvider.of<AuthCubit>(context).uid;
    if (uid == null) return;

    BlocProvider.of<TouchEnabledCubit>(context).disableTouch();
    // TODO: if all good call http function to upload sound

    AddSoundResult r = await FirePP.addSound(
      name: _nameController.text,
      tags: _tags,
      description: _descController.text,
      url: _urlController.text,
      uid: uid,
      explicit:
          explicit, // TODO: add checkbox below sound file if sound file selected, if not don't show. Will be Checkbox with text inside Row
      fileBytes: _selectedAudioFile.bytes,
    );

    BlocProvider.of<TouchEnabledCubit>(context).enableTouch();
  }
}

class SelectedAudioFile {
  SelectedAudioFile(this._f);

  final PlatformFile _f;

  String get name => _f.name;
  int get size => _f.size;
  Uint8List get bytes => _f.bytes;

  String get sizeStr => (size / 1000000).toString() + " MB";

  bool get isSizeOk => this.size < Lengths.max_sound_file_size_bytes;

  bool get isOk => this.isSizeOk;

  String getNotOkMessage() {
    if (!isSizeOk) {
      return "file too big, max file size is 1 MB, selected file size is ${size / 1000000.0} MB";
    }
    return null;
  }
}
