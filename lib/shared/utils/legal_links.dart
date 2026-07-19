import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const String privacyPolicyUrl = 'https://labelwise.net/privacy';
const String termsOfUseUrl = 'https://labelwise.net/terms';
const String disclaimerUrl = 'https://labelwise.net/disclaimer';
const String subscriptionTermsUrl =
    'https://labelwise.net/subscription-terms';
const String contactUrl = 'https://labelwise.net/contact';

Future<void> openLegalUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);

  if (uri == null) {
    _showOpenLinkError(context);
    return;
  }

  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      _showOpenLinkError(context);
    }
  } catch (_) {
    if (context.mounted) {
      _showOpenLinkError(context);
    }
  }
}

void _showOpenLinkError(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Bağlantı açılamadı. Lütfen daha sonra tekrar dene.'),
    ),
  );
}
