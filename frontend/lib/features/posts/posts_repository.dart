import 'package:clone_facebook/core/models/app_models.dart';

/// Team integration contract; an implementation is supplied by this feature's owner.
abstract interface class PostsRepository {
  Future<List<PostModel>> getMyPosts();
}
