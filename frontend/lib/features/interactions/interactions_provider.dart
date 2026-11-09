import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'interactions_repository.dart';

/// Override when this team feature is integrated.
final interactionsRepositoryProvider = Provider<InteractionsRepository?>(
  (ref) => null,
);
