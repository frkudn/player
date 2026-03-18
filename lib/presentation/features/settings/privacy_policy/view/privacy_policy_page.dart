import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(CupertinoIcons.back, size: 24),
        ),
        title: const Text(
          "Privacy Policy",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ListView(
          children: [
            _buildSectionTitle("Privacy Policy for Player"),
            _buildSectionDescription("Effective Date: January 2025", context),
            _buildSectionTitle("Introduction"),
            _buildSectionDescription(
              "Player is an open-source media player designed to provide a rich user experience while respecting your privacy. This Privacy Policy outlines the data we collect, how we use it, and how we protect your personal information.",
              context,
            ),
            _buildSectionTitle("Scope of this Privacy Policy"),
            _buildSectionDescription(
              "This Privacy Policy applies to the Player mobile application (the 'App') available on GitHub and GitLab. By using this App, you consent to the practices outlined in this policy.",
              context,
            ),
            _buildSectionTitle("Information We Collect"),
            _buildSectionDescription(
              "We collect only minimal personal information to improve your experience with Player. This includes user preferences, such as the username or profile picture you may choose to set, which is stored locally on your device. We do not store or share this information with third parties.",
              context,
            ),
            _buildSectionTitle("Data We Do Not Collect"),
            _buildSectionDescription(
              "Player does not collect or store any sensitive personal information. Specifically, we do not track location data, browsing history, audio/video playback history, or any other form of personally identifiable information.",
              context,
            ),
            _buildSectionTitle("Usage of Collected Information"),
            _buildSectionDescription(
              "Any personal information you choose to provide (such as your username or profile picture) is stored solely for your local experience within the App. We do not use this data for any other purpose, nor do we share it with any third parties.",
              context,
            ),
            _buildSectionTitle("Feedback and Support"),
            _buildSectionDescription(
              "Player includes a feedback feature that allows users to send direct input or queries to the developers via email. This feature helps us improve the app but does not collect personal data beyond what you voluntarily provide when contacting us.",
              context,
            ),
            _buildSectionTitle("Security of Your Information"),
            _buildSectionDescription(
              "We employ industry-standard security measures to protect the information stored locally on your device. However, no method of electronic storage or transmission is completely secure, and we cannot guarantee absolute security.",
              context,
            ),
            _buildSectionTitle("Sharing of Information"),
            _buildSectionDescription(
              "We do not share, sell, or rent your personal information to third parties. We respect your privacy and are committed to maintaining the confidentiality of your data.",
              context,
            ),
            _buildSectionTitle("Changes to this Privacy Policy"),
            _buildSectionDescription(
              "Player reserves the right to update or modify this Privacy Policy at any time. Any changes will be reflected on this page with the updated effective date. We encourage users to review this Privacy Policy periodically.",
              context,
            ),
            _buildSectionTitle("Your Rights and Control over Your Data"),
            _buildSectionDescription(
              "You have the right to access, update, or delete any personal information stored locally on your device. You may also request that we delete any information associated with your profile. As the app does not collect any data remotely, any changes made are confined to your device.",
              context,
            ),
            _buildSectionTitle("Contact Information"),
            _buildSectionDescription(
              "If you have any questions or concerns regarding this Privacy Policy, or if you wish to exercise any of your rights described herein, please contact us at:\n\nDeveloper: Furqan Uddin\nEmail: frkudn@protonmail.com",
              context,
            ),
            _buildSectionTitle("Acknowledgement"),
            _buildSectionDescription(
              "By using the Player app, you acknowledge that you have read, understood, and agree to be bound by the terms of this Privacy Policy.",
              context,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSectionDescription(String text, context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white54
              : Colors.black54,
        ),
      ),
    );
  }
}
