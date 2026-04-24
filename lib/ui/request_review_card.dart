import 'package:flutter/material.dart';

import '../../l10n/strings.dart';

class RequestReviewCard extends StatelessWidget {
  const RequestReviewCard({super.key});

  void _showReviewSheet(BuildContext context) {
    final s = S.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.reviewByMeTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.reviewByMeSubtitle,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        s.manualNotAuto,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    s.whatYouGet,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _ReviewBullet(text: s.reviewPoint1),
                  _ReviewBullet(text: s.reviewPoint2),
                  _ReviewBullet(text: s.reviewPoint3),
                  _ReviewBullet(text: s.reviewPoint4),
                  _ReviewBullet(text: s.reviewPoint5),

                  const SizedBox(height: 18),
                  Text(
                    s.idealFor,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _ReviewBullet(text: s.reviewFit1),
                  _ReviewBullet(text: s.reviewFit2),
                  _ReviewBullet(text: s.reviewFit3),

                  const SizedBox(height: 18),
                  Text(
                    s.contactMeLater,
                    style: const TextStyle(color: Colors.black54),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(s.close),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.requestReview,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.reviewCtaHeadline,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              s.reviewCtaBody,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => _showReviewSheet(context),
              icon: const Icon(Icons.fact_check_outlined),
              label: Text(s.requestReview),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewBullet extends StatelessWidget {
  final String text;

  const _ReviewBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(Icons.check_circle_outline, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}