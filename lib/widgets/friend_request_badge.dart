// lib/widgets/friend_request_badge.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/friend_provider.dart';

class FriendRequestBadge extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const FriendRequestBadge({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendProvider>(
      builder: (context, friendProvider, _) {
        final pendingRequestsCount = friendProvider.incomingRequests.length;

        if (pendingRequestsCount == 0) {
          return child;
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            child,
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  '$pendingRequestsCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          ],
        );
      },
    );
  }
}