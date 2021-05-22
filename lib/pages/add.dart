import 'package:flutter/material.dart';
import 'package:klang/constants/transpiled_constants.dart';
import 'package:klang/page_router.dart';
import 'package:klang/pages/klang_page.dart';
import 'package:klang/presets.dart';

class AddPage extends StatelessWidget implements KlangPage {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

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
          ],
        ),
      ),
    );
  }

  @override
  PageRoutePath get route => PageRoutePath.main("/add");
}
