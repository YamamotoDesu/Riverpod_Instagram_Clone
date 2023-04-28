// ignore_for_file: public_member_api_docs, sort_constructors_first


import 'package:flutter/foundation.dart';

import 'package:riverpod_instagram_clone/enums/date_sorting.dart';
import 'package:riverpod_instagram_clone/state/posts/typedefs/post_id.dart';

@immutable
class RequestForPostAndComments {
  final PostId postId;
  final bool sortByCreatedAt;
  final DateSorting dateSorting;
  final int? limit;

  const RequestForPostAndComments({
    required this.postId,
    this.sortByCreatedAt = true,
    this.dateSorting = DateSorting.newestOnTop,
    this.limit,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RequestForPostAndComments &&
          runtimeType == other.runtimeType &&
          postId == other.postId &&
          sortByCreatedAt == other.sortByCreatedAt &&
          dateSorting == other.dateSorting &&
          limit == other.limit;


  @override
  int get hashCode =>
      postId.hashCode ^
      sortByCreatedAt.hashCode ^
      dateSorting.hashCode ^
      limit.hashCode;
}
