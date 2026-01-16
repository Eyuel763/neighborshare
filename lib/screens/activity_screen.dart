import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/request_model.dart';
import 'chat_screen.dart';
import '../utils/ui_helpers.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    final DatabaseService dbService = DatabaseService();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Your Activity',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.blueAccent,
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Borrowing'), 
              Tab(text: 'Lending'), 
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRequestList(
              dbService.getSentRequests(uid),
              isBorrowing: true,
              dbService: dbService,
            ),
            _buildRequestList(
              dbService.getReceivedRequests(uid),
              isBorrowing: false,
              dbService: dbService,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestList(
    Stream<List<RequestModel>> stream, {
    required bool isBorrowing,
    required DatabaseService dbService,
  }) {
    return StreamBuilder<List<RequestModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                const Text(
                  'No active requests found.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final requests = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                title: Text(
                  req.listingTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: _buildStatusSubtitle(req),
                trailing: _buildTrailingWidget(
                  context,
                  req,
                  isBorrowing,
                  dbService,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTrailingWidget(
    BuildContext context,
    RequestModel req,
    bool isBorrowing,
    DatabaseService dbService,
  ) {
    if (req.status == 'completed') {
      return _buildStatusIcon('completed');
    }

    if (req.status == 'accepted') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(
              Icons.chat_bubble_outline,
              color: Colors.blueAccent,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    requestId: req.id,
                    listingTitle: req.listingTitle,
                    otherPartyId: isBorrowing ? req.ownerId : req.requesterId,
                  ),
                ),
              );
            },
          ),
          if (!isBorrowing) // Only the Lender can mark it as returned/completed
            TextButton(
              onPressed: () => _showCompleteDialog(context, req, dbService),
              child: const Text(
                "Complete",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      );
    }

    // PENDING: Owner sees Accept/Decline, Borrower sees Hourglass
    if (!isBorrowing && req.status == 'pending') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
            onPressed: () => dbService.updateRequestStatus(req.id, 'accepted'),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
            onPressed: () => dbService.updateRequestStatus(req.id, 'declined'),
          ),
        ],
      );
    }

    return _buildStatusIcon(req.status);
  }

  void _showCompleteDialog(
    BuildContext context,
    RequestModel req,
    DatabaseService dbService,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Finish Transaction?"),
        content: const Text(
          "Has the item been returned or the service finished? This will close the request.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              await dbService.updateRequestStatus(req.id, 'completed');
              if (context.mounted) {
                Navigator.pop(context); // Close the "Complete" dialog

                showRatingDialog(
                  context: context,
                  targetUserId: req.ownerId,
                  reviewerId: req.requesterId,
                );
              }
            },
            child: const Text(
              "Yes, Completed",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSubtitle(RequestModel req) {
    Color statusColor;
    switch (req.status) {
      case 'accepted':
        statusColor = Colors.green;
        break;
      case 'declined':
        statusColor = Colors.red;
        break;
      case 'completed':
        statusColor = Colors.blueGrey;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        'Status: ${req.status.toUpperCase()}',
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    if (status == 'completed')
      return const Icon(Icons.verified, color: Colors.blueGrey, size: 28);
    if (status == 'declined') return const Icon(Icons.block, color: Colors.red);
    return const Icon(Icons.hourglass_top_rounded, color: Colors.orange);
  }
}
