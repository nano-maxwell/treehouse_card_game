import 'package:flutter/material.dart';
import 'package:treehouse_card_game/cardgame.dart';

class AboutPrivacyPage extends StatelessWidget {
  const AboutPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgPurple,
      appBar: AppBar(
        backgroundColor: bgPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'About & Privacy',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: const [
            Icon(
              Icons.style_rounded,
              color: Colors.white,
              size: 56,
            ),
            SizedBox(height: 12),
            Text(
              'Treehouse Card Game',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 28),
            _InfoCard(
              title: 'Your privacy',
              icon: Icons.privacy_tip_outlined,
              child: Text(
                'Treehouse Card Game does not collect, store, share, or sell '
                'personal information. The game has no accounts, advertising, '
                'analytics, tracking, in-app purchases, or online features.',
              ),
            ),
            SizedBox(height: 14),
            _InfoCard(
              title: 'How the game works',
              icon: Icons.cloud_off_outlined,
              child: Text(
                'The game works offline. Your progress is only kept while the '
                'current game is open and is not saved after you leave or close '
                'the app.',
              ),
            ),
            SizedBox(height: 14),
            _InfoCard(
              title: 'Privacy-policy updates',
              icon: Icons.update_outlined,
              child: Text(
                'If the app’s data practices change, this page and the App '
                'Store privacy information will be updated before the change '
                'takes effect.',
              ),
            ),
            SizedBox(height: 14),
            _InfoCard(
              title: 'Support',
              icon: Icons.support_agent_outlined,
              child: Text(
                'A public support contact and privacy-policy website will be '
                'added before the App Store release.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: title,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: darkerPurple),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DefaultTextStyle.merge(
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  height: 1.35,
                ),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
