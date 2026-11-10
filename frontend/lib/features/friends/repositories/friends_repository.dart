import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clone_facebook/core/network/api_client.dart';

import '../models/friend_request.dart';

abstract interface class FriendsRepository {
  Future<List<FriendRequest>> connections(String kind);
  Future<void> sendRequest(String receiverId);
  Future<void> changeRequest(String requestId, String action);
}

class ApiFriendsRepository implements FriendsRepository {
  ApiFriendsRepository(this.client);
  final ApiClient client;
  @override
  Future<List<FriendRequest>> connections(String kind) async {
    final path = kind == 'friends' ? '/friends' : '/friends/requests/$kind';
    final rows = <FriendRequest>[];
    var page = 1;
    // Each HTTP response is bounded. Follow pages for the in-memory friend filter.
    while (true) {
      final response = await client.get<Map<String, dynamic>>(
        path,
        queryParameters: {'page': page, 'limit': 100},
      );
      final json = response.data!;
      final batch = (json['data'] as List).cast<Map<String, dynamic>>();
      rows.addAll(batch.map(FriendRequest.fromJson));
      if (!(json['pagination']['has_more'] as bool)) break;
      page++;
    }
    // Polling while another device changes a request may move a page boundary.
    return {for (final row in rows) row.id: row}.values.toList();
  }

  @override
  Future<void> sendRequest(String receiverId) async {
    await client.post('/friends/requests', data: {'receiver_id': receiverId});
  }

  @override
  Future<void> changeRequest(String requestId, String action) async {
    await client.patch('/friends/requests/$requestId/$action');
  }
}

final friendsRepositoryProvider = Provider<FriendsRepository>(
  (ref) => ApiFriendsRepository(ref.watch(apiClientProvider)),
);
