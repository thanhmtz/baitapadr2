import 'package:bp_notepad/events/reminderBloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bp_notepad/screens/mainScreen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:bp_notepad/localization/languageConstants.dart';
import 'package:bp_notepad/localization/appLocalization.dart';
import 'package:bp_notepad/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(BpNotepad());
}

class BpNotepad extends StatefulWidget {
  const BpNotepad({Key key}) : super(key: key);

  static void setLocale(BuildContext context, Locale newLocale) {
    _BpNotepadState state =
    context.findAncestorStateOfType<_BpNotepadState>();
    state.setLocale(newLocale);
  }

  @override
  _BpNotepadState createState() => _BpNotepadState();
}

class _BpNotepadState extends State<BpNotepad> {
  Locale _locale;

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  void didChangeDependencies() {
    getLocale().then((locale) {
      setState(() {
        _locale = locale;
      });
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReminderBloc>(
      create: (context) => ReminderBloc(),
      child: ValueListenableBuilder<bool>(
        valueListenable: isDarkModeGlobal,
        builder: (context, isDarkMode, _) {
          return CupertinoApp(
            debugShowCheckedModeBanner: false,
            title: "BP Notepad",

            // 🌙 Theme Cupertino
            theme: CupertinoThemeData(
              brightness:
              isDarkMode ? Brightness.dark : Brightness.light,
            ),

            // 🔥 FIX QUAN TRỌNG: đồng bộ Material + nền
            builder: (context, child) {
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: isDarkMode 
                    ? SystemUiOverlayStyle.light 
                    : SystemUiOverlayStyle.dark,
                child: Material(
                  color: isDarkMode ? Color(0xFF121212) : Colors.white,
                  child: Theme(
                    data: ThemeData(
                      brightness: isDarkMode ? Brightness.dark : Brightness.light,
                      scaffoldBackgroundColor: isDarkMode ? Color(0xFF121212) : Colors.white,
                      cardColor: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
                      textTheme: TextTheme(
                        bodyText1: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                        bodyText2: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                        headline6: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                      ),
                    ),
                    child: child,
                  ),
                ),
              );
            },

            locale: _locale,
            supportedLocales: const [
              Locale("en"),
              Locale("vi"),
              Locale("zh"),
              Locale("ja"),
            ],

            localizationsDelegates: const [
              AppLocalization.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            localeResolutionCallback:
                (locale, supportedLocales) {
              if (locale == null) return supportedLocales.first;
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode ==
                    locale.languageCode) {
                  return supportedLocale;
                }
              }
              return supportedLocales.first;
            },

            home: MainScreen(),
          );
        },
      ),
    );
  }
}