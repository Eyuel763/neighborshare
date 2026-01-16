import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../services/database_service.dart';

void showRatingDialog({
  required BuildContext context,
  required String targetUserId,
  required String reviewerId,
}) {
  double currentRating = 5.0; 
  final TextEditingController commentController = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: false, 
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text("Rate your Experience", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("How was the item and the neighbor?"),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < currentRating ? Icons.star : Icons.star_border,
                    color: Colors.orange,
                    size: 35,
                  ),
                  onPressed: () => setState(() => currentRating = index + 1.0),
                );
              }),
            ),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(hintText: "Add a comment..."),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Skip")),
          ElevatedButton(
            onPressed: () async {
              final review = ReviewModel(
                id: '',
                reviewerId: reviewerId,
                targetUserId: targetUserId,
                rating: currentRating,
                comment: commentController.text,
                createdAt: DateTime.now(),
              );
              await DatabaseService().submitReview(review);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    ),
  );
}