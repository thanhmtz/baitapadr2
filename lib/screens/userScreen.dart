import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar;
import 'package:bp_notepad/localization/appLocalization.dart';
import 'package:bp_notepad/screens/FunctionScreen/exportPDF.dart';
import 'package:bp_notepad/screens/languageView.dart';
import 'package:bp_notepad/theme.dart';

class UserScreen extends StatefulWidget {
  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoDynamicColor.resolve(
        CupertinoColors.systemGroupedBackground, context),
      navigationBar: CupertinoNavigationBar(
        middle: Text('Cá nhân'),
      ),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // PROFILE
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF5856D6), Color(0xFF007AFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: AssetImage("assets/images/aboutMe.jpeg"),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Thành",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.white,
                        ),
                      ),
                      Text(
                        "User",
                        style: TextStyle(
                          color: CupertinoColors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // SETTINGS
            _buildSettingItem(
              icon: CupertinoIcons.moon_fill,
              title: 'Chế độ ban đêm',
              trailing: CupertinoSwitch(
                value: isDarkModeGlobal.value,
                onChanged: (value) {
                  setState(() {
                    isDarkModeGlobal.value = value;
                  });
                },
              ),
            ),
            
            _buildSettingItem(
              icon: CupertinoIcons.globe,
              title: 'Ngôn ngữ',
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) => LanguageView()),
                );
              },
            ),
            
            _buildSettingItem(
              icon: CupertinoIcons.doc_text,
              title: 'Xuất PDF',
              onTap: () => generateInvoice(),
            ),
            
            _buildSettingItem(
              icon: CupertinoIcons.info,
              title: 'Về ứng dụng',
              onTap: () => showAboutDialog(context),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingItem({
    IconData icon,
    String title,
    Widget trailing,
    VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoDynamicColor.resolve(
            CupertinoColors.secondarySystemGroupedBackground, context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: CupertinoColors.systemBlue),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 16),
              ),
            ),
            if (trailing != null)
              trailing
            else
              Icon(
                CupertinoIcons.chevron_right,
                color: CupertinoColors.systemGrey3,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
  
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