import 'package:bp_notepad/localization/appLocalization.dart';
import 'package:bp_notepad/screens/FunctionScreen/exportPDF.dart';
import 'package:bp_notepad/screens/languageView.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bp_notepad/theme.dart';

const List<Icon> icons = [
  Icon(CupertinoIcons.arrowshape_turn_up_right_circle,
      size: 28, color: Color(0xFF50C1F9)),
  Icon(CupertinoIcons.gear,
      size: 28, color: Color(0xFF00E0DE)),
  Icon(CupertinoIcons.globe,
      size: 28, color: Color(0xFF006FFF)),
];

class AboutScreen extends StatefulWidget {
  @override
  _AboutScreenState createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool isNotification = true;

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkModeGlobal.value;

    List tittleTexts = [
      AppLocalization.of(context).translate('file_export'),
      AppLocalization.of(context).translate('user_cog'),
      AppLocalization.of(context).translate('language'),
    ];

    return CupertinoPageScaffold(
      backgroundColor:
      CupertinoDynamicColor.resolve(backGroundColor, context),

      navigationBar: CupertinoNavigationBar(
        middle: Text(
          AppLocalization.of(context).translate('setting_page'),
        ),
      ),

      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(8),
          children: [

            // 👤 PROFILE
            _buildCard(
              context,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage:
                    NetworkImage("https://i.imgur.com/BoN9kdC.png"),
                  ),
                  SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Thành",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyText1?.color,
                        ),
                      ),
                      Text(
                        "User",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  )
                ],
              ),
            ),

            SizedBox(height: 10),

            // 📄 EXPORT PDF
            _buildTile(
              context,
              icon: icons[0],
              title: tittleTexts[0],
              onTap: () => generateInvoice(),
            ),

            // 🌙 DARK MODE (FIX CHUẨN)
            _buildSwitch(
              context,
              icon: Icon(CupertinoIcons.moon),
              title: AppLocalization.of(context)
                  ?.translate("Dark Mode") ??
                  "Dark Mode",
              value: isDarkModeGlobal.value,
              onChanged: (value) {
                isDarkModeGlobal.value = value;
              },
            ),

            // 🔔 NOTIFICATION
            _buildSwitch(
              context,
              icon: Icon(CupertinoIcons.bell),
              title: AppLocalization.of(context)
                  ?.translate("Notification") ??
                  "Notification",
              value: isNotification,
              onChanged: (value) {
                setState(() {
                  isNotification = value;
                });
              },
            ),

            // 🌍 LANGUAGE
            _buildTile(
              context,
              icon: icons[2],
              title: tittleTexts[2],
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                      builder: (context) => LanguageView()),
                );
              },
            ),

            // ℹ️ ABOUT
            _buildTile(
              context,
              icon: Icon(CupertinoIcons.info),
              title: AppLocalization.of(context)
                  ?.translate("About App") ??
                  "About App",
              onTap: () {
                showAboutDialog(context);
              },
            ),

            // 🚪 LOGOUT
            _buildTile(
              context,
              icon: Icon(CupertinoIcons.square_arrow_right,
                  color: Colors.red),
              title: AppLocalization.of(context)
                  ?.translate("Logout") ??
                  "Logout",
              color: Colors.red,
              onTap: () {
                print("Logout");
              },
            ),
          ],
        ),
      ),
    );
  }

  // ===== UI COMPONENTS =====

  Widget _buildCard(BuildContext context, {Widget child}) {
    return Container(
      margin: EdgeInsets.all(5),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color:
        CupertinoDynamicColor.resolve(backGroundColor, context),
        borderRadius: BorderRadius.circular(15),
      ),
      child: child,
    );
  }

  Widget _buildTile(BuildContext context,
      {Icon icon, String title, Function onTap, Color color}) {
    return Card(
      color: Theme.of(context).cardColor, // 🔥 FIX DARK MODE
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: icon,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            color: color ??
                Theme.of(context).textTheme.bodyText1?.color,
          ),
        ),
        trailing: Icon(CupertinoIcons.chevron_forward),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitch(BuildContext context,
      {Icon icon, String title, bool value, Function onChanged}) {
    return Card(
      color: Theme.of(context).cardColor, // 🔥 FIX
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: icon,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            color:Theme.of(context).textTheme.bodyText1?.color,
          ),
        ),
        trailing: CupertinoSwitch(
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ===== ABOUT DIALOG =====

  void showAboutDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text("BP Notepad"),
        content: Text("App quản lý sức khỏe\nVersion 1.0"),
        actions: [
          CupertinoDialogAction(
            child: Text("OK"),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }
}