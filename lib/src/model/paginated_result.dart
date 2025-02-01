import 'package:cloud_firestore/cloud_firestore.dart';

/// A generic class that represents a paginated result set from Firestore queries.
///
/// The [PaginatedResult] class encapsulates the data and metadata necessary for
/// implementing pagination in Firestore queries. It holds:
/// * The current page of items
/// * A reference to the last document (for fetching the next page)
/// * A flag indicating if more data is available
///
/// Example usage:
/// ```dart
/// // Fetch the first page
/// PaginatedResult<User> result = await firecraft.fetchInitialPage(
///   collectionPath: 'users',
///   fromJson: User.fromJson,
///   limit: 20,
/// );
///
/// // Display items
/// for (var user in result.items) {
///   print(user.name);
/// }
///
/// // Check if more pages exist
/// if (result.hasMore) {
///   // Fetch next page using lastDocument
///   final nextPage = await firecraft.fetchNextPage(
///     collectionPath: 'users',
///     fromJson: User.fromJson,
///     lastDocument: result.lastDocument!,
///     limit: 20,
///   );
/// }
/// ```
class PaginatedResult<T> {
  /// Creates a new instance of [PaginatedResult].
  ///
  /// Parameters:
  /// * [items] - The list of items in the current page
  /// * [hasMore] - Whether there are more items available to fetch
  /// * [lastDocument] - The last document in the current page, used for fetching the next page
  PaginatedResult({
    required this.items,
    required this.hasMore,
    this.lastDocument,
  });

  /// The list of items in the current page.
  ///
  /// This list contains the actual data items of type [T] that were fetched
  /// from the Firestore query.
  final List<T> items;

  /// A reference to the last document in the current page.
  ///
  /// This is used as a cursor for fetching the next page of results.
  /// It will be null if there are no items in the current page or if
  /// this is the last page.
  final DocumentSnapshot? lastDocument;

  /// Indicates whether there are more items available to fetch.
  ///
  /// This flag is true if there are more items available beyond the
  /// current page, and false if this is the last page of results.
  final bool hasMore;
}
