import 'package:bp_notepad/localization/appLocalization.dart';
import 'package:bp_notepad/localization/language.dart';
import 'package:bp_notepad/localization/languageConstants.dart';
import 'package:flutter/cupertino.dart';
import '../main.dart';
import 'package:bp_notepad/theme.dart';

class LanguageView extends StatefulWidget {
  @override
  _LanguageViewState createState() => _LanguageViewState();
}

class _LanguageViewState extends State<LanguageView> {

  void _changeLanguage(String code) async {
    await setLocale(code);
    BpNotepad.setLocale(context, Locale(code));
  }

  @override
  Widget build(BuildContext context) {
    Locale currentLocale = Localizations.localeOf(context);

    final languages = Language.languageList();

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.surface(),
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          AppLocalization.of(context).translate('language'),
        ),
      ),

      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: 20),

          children: [

            /// 🔥 SECTION (giống iOS Settings)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: CupertinoColors.secondarySystemGroupedBackground
                    .resolveFrom(context),
                borderRadius: BorderRadius.circular(14),
              ),

              child: Column(
                children: List.generate(languages.length, (index) {
                  final lang = languages[index];
                  bool isSelected =
                      lang.languageCode == currentLocale.languageCode;

                  return Column(
                    children: [

                      /// ITEM
                      GestureDetector(
                        onTap: () {
                          _changeLanguage(lang.languageCode);
                          setState(() {});
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),

                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [

                              /// TEXT
                              Text(
                                lang.name,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? CupertinoColors.activeBlue
                                      : CupertinoColors.label,
                                ),
                              ),

                              /// CHECK
                              if (isSelected)
                                Icon(
                                  CupertinoIcons.check_mark,
                                  color:
                                  CupertinoColors.activeBlue,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),

                      /// DIVIDER (trừ item cuối)
                      if (index != languages.length - 1)
                        Container(
                          margin: EdgeInsets.only(left: 16),
                          height: 0.5,
                          color: CupertinoColors.separator
                              .resolveFrom(context),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}