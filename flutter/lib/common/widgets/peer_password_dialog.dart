import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/widgets/custom_password.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:get/get.dart';

/// Asks for a new permanent password and sends it to the controlled device.
/// The device answers with a message box saying whether it was applied.
void showChangePeerPasswordDialog(
    String id, SessionID sessionId, OverlayDialogManager dialogManager) {
  final p0 = TextEditingController(text: "");
  final p1 = TextEditingController(text: "");
  var errMsg0 = "";
  var errMsg1 = "";
  final RxString rxPass = "".obs;
  final rules = [
    DigitValidationRule(),
    UppercaseValidationRule(),
    LowercaseValidationRule(),
    MinCharactersValidationRule(8),
  ];
  final maxLength = bind.mainMaxEncryptLen();

  dialogManager.show((setState, close, context) {
    submit() {
      final pass = p0.text.trim();
      final violations = rules.where((r) => !r.validate(pass));
      if (violations.isNotEmpty) {
        setState(() {
          errMsg0 =
              '${translate('Prompt')}: ${violations.map((r) => r.name).join(', ')}';
        });
        return;
      }
      if (p1.text.trim() != pass) {
        setState(() {
          errMsg1 =
              '${translate('Prompt')}: ${translate("The confirmation is not identical.")}';
        });
        return;
      }
      bind.sessionChangePeerPermanentPassword(
          sessionId: sessionId, password: pass);
      close();
    }

    return CustomAlertDialog(
      title: Row(children: [
        Icon(Icons.key, color: MyTheme.accent),
        Flexible(
            child: Text(translate("Change client password"))
                .paddingOnly(left: 10)),
      ]),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(translate("change-client-password-tip"),
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              obscureText: true,
              autofocus: true,
              maxLength: maxLength,
              controller: p0,
              decoration: InputDecoration(
                  labelText: translate('Password'),
                  errorText: errMsg0.isNotEmpty ? errMsg0 : null),
              onChanged: (value) {
                rxPass.value = value.trim();
                setState(() => errMsg0 = '');
              },
            ),
            PasswordStrengthIndicator(password: rxPass),
            const SizedBox(height: 8),
            TextField(
              obscureText: true,
              maxLength: maxLength,
              controller: p1,
              decoration: InputDecoration(
                  labelText: translate('Confirmation'),
                  errorText: errMsg1.isNotEmpty ? errMsg1 : null),
              onChanged: (_) => setState(() => errMsg1 = ''),
              onSubmitted: (_) => submit(),
            ),
            const SizedBox(height: 8),
            Obx(() => Wrap(
                  runSpacing: 8,
                  spacing: 4,
                  children: rules.map((e) {
                    final checked = e.validate(rxPass.value);
                    return Chip(
                        label: Text(
                          e.name,
                          style: TextStyle(
                              color: checked
                                  ? const Color(0xFF0A9471)
                                  : const Color.fromARGB(255, 198, 86, 157)),
                        ),
                        backgroundColor: checked
                            ? const Color(0xFFD0F7ED)
                            : const Color.fromARGB(255, 247, 205, 232));
                  }).toList(),
                )),
          ],
        ),
      ),
      actions: [
        dialogButton(
          "Cancel",
          icon: Icon(Icons.close_rounded),
          onPressed: close,
          isOutline: true,
        ),
        dialogButton(
          "OK",
          icon: Icon(Icons.done_rounded),
          onPressed: submit,
        ),
      ],
      onCancel: close,
      onSubmit: submit,
    );
  });
}
