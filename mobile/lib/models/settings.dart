import 'dart:convert';

enum ConnectionMode { lan, hotspot, cellular }

class AppSettings {
  AppSettings({
    this.inspectorName = '',
    this.companyName = '',
    this.companyPhone = '',
    this.companyEmail = '',
    this.defaultEmailSubject = '{{inspectionType}} Report — {{siteAddress}}',
    this.defaultEmailBody =
        'Hi {{clientName}},\n\nPlease find attached the inspection report for {{siteAddress}}.\n\nKind regards,\n{{inspectorName}}\n{{companyName}}',
    this.apiBaseUrl = 'http://192.168.1.94:3001',
    this.localServerEnabled = true,
    this.appearanceDark = true,
    this.useBigKeyboard = true,
    this.preferredConnectionMode = ConnectionMode.lan,
  });

  String inspectorName;
  String companyName;
  String companyPhone;
  String companyEmail;
  String defaultEmailSubject;
  String defaultEmailBody;
  String apiBaseUrl;
  bool localServerEnabled;
  bool appearanceDark;
  bool useBigKeyboard;
  ConnectionMode preferredConnectionMode;

  Map<String, dynamic> toJson() => {
        'inspectorName': inspectorName,
        'companyName': companyName,
        'companyPhone': companyPhone,
        'companyEmail': companyEmail,
        'defaultEmailSubject': defaultEmailSubject,
        'defaultEmailBody': defaultEmailBody,
        'apiBaseUrl': apiBaseUrl,
        'localServerEnabled': localServerEnabled,
        'appearanceDark': appearanceDark,
        'useBigKeyboard': useBigKeyboard,
        'preferredConnectionMode': preferredConnectionMode.name,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        inspectorName: j['inspectorName'] as String? ?? '',
        companyName: j['companyName'] as String? ?? '',
        companyPhone: j['companyPhone'] as String? ?? '',
        companyEmail: j['companyEmail'] as String? ?? '',
        defaultEmailSubject: j['defaultEmailSubject'] as String? ??
            '{{inspectionType}} Report — {{siteAddress}}',
        defaultEmailBody: j['defaultEmailBody'] as String? ?? '',
        apiBaseUrl: j['apiBaseUrl'] as String? ?? 'http://192.168.1.94:3001',
        localServerEnabled: j['localServerEnabled'] as bool? ?? true,
        appearanceDark: j['appearanceDark'] as bool? ?? true,
        useBigKeyboard: j['useBigKeyboard'] as bool? ?? true,
        preferredConnectionMode: _parseConnectionMode(
          j['preferredConnectionMode'] as String?,
        ),
      );

  static ConnectionMode _parseConnectionMode(String? raw) {
    final name = raw ?? 'lan';
    if (name == 'cellular') return ConnectionMode.hotspot;
    return ConnectionMode.values.byName(name);
  }

  static AppSettings decode(String raw) => AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  String encode() => jsonEncode(toJson());
}