import 'package:flutter/material.dart';

import '../../core/app_info.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// A section of legal/guideline copy. The body may contain multiple
/// paragraphs separated by a blank line ("\n\n").
class ContentSection {
  const ContentSection(this.heading, this.body);
  final String heading;
  final String body;
}

/// A reusable, readable page for guidelines / terms / privacy policy.
class ContentPage extends StatelessWidget {
  const ContentPage({
    super.key,
    required this.title,
    required this.intro,
    required this.sections,
    this.showEffectiveDate = false,
    this.footer,
  });

  final String title;
  final String intro;
  final List<ContentSection> sections;

  /// Legal documents show a "Last updated" line; guidelines do not.
  final bool showEffectiveDate;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (showEffectiveDate) ...[
              Text('Last updated: ${AppInfo.lastUpdated}',
                  style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.inkFaint,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(intro,
                style: const TextStyle(
                    fontSize: 18, height: 1.5, color: AppColors.inkSoft)),
            const SizedBox(height: AppSpacing.lg),
            ...sections.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.heading,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Text(s.body,
                          style: const TextStyle(
                              fontSize: 17, height: 1.5, color: AppColors.ink)),
                    ],
                  ),
                )),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(footer!,
                    style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.inkFaint)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Prebuilt content pages.
///
/// NOTE: These texts are an EU/GDPR-aware template, not legal advice. Review
/// with a qualified adviser and complete the placeholders in [AppInfo]
/// (company name, address, contact email, supervisory authority) before
/// publishing.
class LegalContent {
  LegalContent._();

  static const communityGuidelines = ContentPage(
    title: 'Community guidelines',
    intro:
        'This is a community built on kindness and respect. A few simple '
        'principles keep it welcoming for everyone.',
    sections: [
      ContentSection('Be kind and respectful',
          'Treat others the way you would like to be treated. Friendly, '
              'courteous conversation is what this community is all about.'),
      ContentSection('This is about friendship',
          'We are here to make friends, share interests and enjoy activities '
              'together. This is not a dating service, and content of a '
              'romantic or sexual nature is not welcome.'),
      ContentSection('Protect your privacy and others’',
          'Never share your home address, financial details or passwords, and '
              'do not share other people’s personal information without their '
              'consent. Meet in public places when you meet in person.'),
      ContentSection('No harassment or hate',
          'Bullying, hate speech, discrimination and unwanted attention are '
              'not tolerated and may lead to removal from the community.'),
      ContentSection('No scams or solicitation',
          'Requests for money, investment schemes, advertising and spam are '
              'not allowed. Please report anyone who asks you for money.'),
      ContentSection('Report anything that feels wrong',
          'If someone makes you uncomfortable, you can block and report them '
              'at any time from their profile or your conversation. Reports '
              'are confidential and reviewed by our team.'),
    ],
  );

  static final terms = ContentPage(
    title: 'Terms of service',
    showEffectiveDate: true,
    intro:
        'These Terms of Service ("Terms") govern your use of the '
        '${AppInfo.appName} mobile application ("the app"), provided by '
        '${AppInfo.companyName}. By creating an account or using the app, you '
        'agree to these Terms. If you do not agree, please do not use the app.',
    footer:
        'These Terms are governed by the laws of the country where '
        '${AppInfo.companyName} is established, without prejudice to the '
        'mandatory consumer-protection rights you have under the laws of your '
        'country of residence in the EU/EEA. Contact: ${AppInfo.supportEmail}.',
    sections: [
      ContentSection('1. Who we are',
          '${AppInfo.appName} is operated by ${AppInfo.companyName}, '
              '${AppInfo.companyAddress}. You can contact us at '
              '${AppInfo.supportEmail}.'),
      ContentSection('2. Eligibility',
          'You must be at least ${AppInfo.minimumAge} years old and legally '
              'able to enter into a contract to use the app. The app is '
              'designed for adults who wish to build local friendships and '
              'take part in activities.'),
      ContentSection('3. Your account',
          'You are responsible for keeping your login details secure and for '
              'activity that happens under your account. Please provide '
              'accurate information and keep it up to date.'),
      ContentSection('4. Acceptable use',
          'You agree to follow our Community Guidelines. You must not use the '
              'app to harass, deceive, defraud or harm others, to post '
              'unlawful or offensive content, or to collect other users’ data '
              'without consent. We may suspend or remove accounts that break '
              'these rules.'),
      ContentSection('5. Your content',
          'You keep ownership of the content you add (such as your photo, '
              'introduction and messages). You grant us a limited licence to '
              'store and display that content within the app so the service '
              'can function. You are responsible for the content you share.'),
      ContentSection('6. Meeting in person',
          'The app helps you connect, but any meeting in the real world is '
              'your own decision and at your own risk. Please take sensible '
              'precautions and meet in public places.'),
      ContentSection('7. Subscriptions and payments',
          'The core social features are free. Optional Premium features are '
              'sold as auto-renewing subscriptions billed through the Apple '
              'App Store or Google Play. Payment is charged to your store '
              'account at confirmation of purchase. Subscriptions renew '
              'automatically unless cancelled at least 24 hours before the end '
              'of the current period; manage or cancel them in your store '
              'account settings.'),
      ContentSection('8. Right of withdrawal (EU)',
          'As digital content supplied immediately, you may be asked to '
              'consent to the service beginning right away, acknowledging that '
              'you then lose the 14-day right of withdrawal for that purchase '
              'under EU consumer law. Store refund policies also apply.'),
      ContentSection('9. Availability and changes',
          'We may update, suspend or discontinue features. We may change '
              'these Terms; if the changes are significant we will notify you '
              'in the app and, where required, ask for your agreement.'),
      ContentSection('10. Liability',
          'Nothing in these Terms limits liability that cannot be limited by '
              'law (including for death or personal injury caused by '
              'negligence). Otherwise, to the extent permitted by law, the app '
              'is provided "as is" and we are not liable for the conduct of '
              'other users.'),
      ContentSection('11. Ending your use',
          'You can stop using the app and delete your account at any time from '
              'Settings. We may end your access if you seriously or repeatedly '
              'break these Terms or the Community Guidelines.'),
    ],
  );

  static final privacyPolicy = ContentPage(
    title: 'Privacy policy',
    showEffectiveDate: true,
    intro:
        'This Privacy Policy explains how ${AppInfo.companyName} ("we") '
        'collects and uses your personal data when you use ${AppInfo.appName}, '
        'and the rights you have under the EU General Data Protection '
        'Regulation (GDPR). We collect only what we need to help you meet '
        'people nearby, and we protect it carefully.',
    footer:
        'This policy is provided in good faith to meet GDPR transparency '
        'requirements. Please review it with a qualified adviser and complete '
        'the controller details before publishing.',
    sections: [
      ContentSection('1. Data controller',
          'The controller responsible for your personal data is '
              '${AppInfo.companyName}, ${AppInfo.companyAddress}. '
              'For any privacy question or to exercise your rights, contact us '
              'at ${AppInfo.contactEmail}. ${AppInfo.dpoContact}.'),
      ContentSection('2. What we collect',
          'Account data: your email address and password (stored securely).\n\n'
              'Profile data: your first name, age range, country, city and '
              'approximate area, interests, what you are looking for, your '
              'short introduction and (optionally) a profile photo.\n\n'
              'Activity data: activities you create or join, interests you '
              'express, matches, and the messages you send.\n\n'
              'Technical data: basic device and diagnostic information needed '
              'to run the service and keep it secure.'),
      ContentSection('3. What we do NOT collect or show',
          'We do not store your exact home address or precise real-time '
              'location — only your city and an approximate area. We never '
              'publicly display your email address, phone number or exact '
              'location to other users.'),
      ContentSection('4. Why we use your data and legal bases',
          'To provide the service — showing you people and activities nearby '
              'and enabling matches and messaging (Art. 6(1)(b) GDPR, '
              'performance of a contract).\n\n'
              'To keep the community safe — handling blocks, reports and abuse '
              'prevention (Art. 6(1)(f), our legitimate interest in a safe '
              'service).\n\n'
              'To send optional push notifications — only with your consent, '
              'which you can withdraw at any time in Notification settings '
              '(Art. 6(1)(a)).\n\n'
              'To meet legal obligations, such as responding to lawful '
              'requests (Art. 6(1)(c)).'),
      ContentSection('5. Sharing your data',
          'Your profile is visible to other users of the app as described '
              'above. We use service providers ("processors") who act on our '
              'instructions — for example cloud hosting and database, '
              'subscription management and push notifications. We do not sell '
              'your personal data.'),
      ContentSection('6. International transfers',
          'Where a provider processes data outside the EU/EEA, we rely on '
              'appropriate safeguards such as the European Commission’s '
              'Standard Contractual Clauses or an adequacy decision.'),
      ContentSection('7. How long we keep it',
          'We keep your data while your account is active. When you delete '
              'your account, we delete or anonymise your personal data without '
              'undue delay, except where we must keep certain records to meet '
              'legal obligations or resolve disputes.'),
      ContentSection('8. Your rights',
          'Under the GDPR you have the right to access your data; to correct '
              'inaccurate data; to erasure ("right to be forgotten"); to '
              'restrict or object to processing; to data portability; and to '
              'withdraw consent at any time. You can edit your profile, manage '
              'notifications and delete your account directly in the app, or '
              'contact us at ${AppInfo.contactEmail}.'),
      ContentSection('9. Right to complain',
          'If you believe we have handled your data unlawfully, you can lodge '
              'a complaint with a supervisory authority — '
              '${AppInfo.supervisoryAuthority}, or the authority in your EU/EEA '
              'country of residence.'),
      ContentSection('10. Children',
          'The app is only for people aged ${AppInfo.minimumAge} and over. We '
              'do not knowingly collect data from anyone under this age.'),
      ContentSection('11. Changes to this policy',
          'We may update this policy. If changes are significant we will '
              'notify you in the app. The "Last updated" date above shows the '
              'current version.'),
    ],
  );
}
