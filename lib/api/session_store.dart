import 'dart:convert';

// Secure storage is disabled: tokens are written to shared_preferences instead.
// To restore the old behaviour, uncomment the import and the storage instance
// below and swap the preference helpers back to secure storage.
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';

// const _secureStorage = FlutterSecureStorage(
//   aOptions: AndroidOptions(encryptedSharedPreferences: true),
//   mOptions: MacOsOptions(useDataProtectionKeyChain: false),
// );

class AccountRecord {
  final String id;
  final String label;
  final String baseUrl;
  final String token;

  const AccountRecord({
    required this.id,
    required this.label,
    required this.baseUrl,
    required this.token,
  });

  Map<String, String> toJson() => {
    'id': id,
    'label': label,
    'baseUrl': baseUrl,
  };

  factory AccountRecord.fromJson(Map<String, dynamic> json) => AccountRecord(
    id: json['id'] as String? ?? '',
    label: json['label'] as String? ?? L10n.current.settingsAccountDefaultLabel,
    baseUrl: json['baseUrl'] as String? ?? '',
    token: json['token'] as String? ?? '',
  );

  static String idFor(String baseUrl, [String identity = 'legacy']) =>
      '$baseUrl\u0000$identity';
}

class SessionStore {
  const SessionStore._();

  static const String tokenKey = 'qutty.token';
  static const String apiUrlKey = 'qutty.api_url';
  static const String accountsKey = 'qutty.accounts';
  static const String activeAccountKey = 'qutty.active_account';

  // static FlutterSecureStorage get secureStorage => _secureStorage;

  static String accountTokenKey(String accountId) =>
      'qutty.account_token.${base64Url.encode(utf8.encode(accountId))}';

  /// Writes a token value to the regular preference store.
  static Future<void> _writeSecret(String key, String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, value);
  }

  /// Removes a token value from the regular preference store.
  static Future<void> _deleteSecret(String key) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(key);
  }

  static Future<void> saveAccountToken(String accountId, String token) async {
    await _writeSecret(accountTokenKey(accountId), token);
  }

  static Future<void> deleteAccountToken(String accountId) async {
    await _deleteSecret(accountTokenKey(accountId));
  }

  static Future<List<AccountRecord>> readAccounts(
    SharedPreferences preferences,
  ) async {
    final raw = preferences.getString(accountsKey);
    if (raw == null) return const [];

    late final List<AccountRecord> saved;
    try {
      saved = (jsonDecode(raw) as List<dynamic>)
          .map((item) => AccountRecord.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }

    final accounts = <AccountRecord>[];
    var migrated = false;
    for (final account in saved) {
      final oldTokenInId =
          account.id == '${account.baseUrl}\u0000${account.token}';
      final id = oldTokenInId
          ? AccountRecord.idFor(account.baseUrl)
          : account.id;
      final token = preferences.getString(accountTokenKey(id));
      final resolvedToken = token?.isNotEmpty == true ? token! : account.token;
      if (resolvedToken.isEmpty || id.isEmpty) continue;
      if (token == null || oldTokenInId || account.token.isNotEmpty) {
        await saveAccountToken(id, resolvedToken);
        migrated = true;
      }
      accounts.add(
        AccountRecord(
          id: id,
          label: account.label,
          baseUrl: account.baseUrl,
          token: resolvedToken,
        ),
      );
      if (id != account.id || account.token.isNotEmpty) migrated = true;
    }
    if (migrated) {
      final activeId = preferences.getString(activeAccountKey);
      final previous = saved
          .where((account) => account.id == activeId)
          .firstOrNull;
      if (previous != null &&
          previous.id == '${previous.baseUrl}\u0000${previous.token}') {
        await preferences.setString(
          activeAccountKey,
          AccountRecord.idFor(previous.baseUrl),
        );
      }
      await preferences.setString(
        accountsKey,
        jsonEncode(accounts.map((account) => account.toJson()).toList()),
      );
    }
    return accounts;
  }

  static Future<AccountRecord?> readActive(
    SharedPreferences preferences, {
    required String fallbackBaseUrl,
  }) async {
    var accounts = await readAccounts(preferences);

    if (accounts.isEmpty) {
      final legacyToken = preferences.getString(tokenKey);
      final savedUrl = preferences.getString(apiUrlKey);
      if (legacyToken == null || legacyToken.isEmpty) return null;
      final baseUrl = (savedUrl?.isNotEmpty ?? false)
          ? savedUrl!
          : fallbackBaseUrl;
      accounts = [
        AccountRecord(
          id: AccountRecord.idFor(baseUrl),
          label: L10n.current.settingsAccountDefaultLabel,
          baseUrl: baseUrl,
          token: legacyToken,
        ),
      ];
    }

    final activeId = preferences.getString(activeAccountKey);
    for (final account in accounts) {
      if (account.id == activeId) return account;
    }
    return accounts.isEmpty ? null : accounts.first;
  }

  static Future<void> saveToken(String token) async {
    await _writeSecret(tokenKey, token);
  }

  static Future<void> deleteToken() async {
    await _deleteSecret(tokenKey);
  }
}
