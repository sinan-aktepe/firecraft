import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firecraft/src/model/paginated_result.dart';

/// A utility class that provides a simplified interface for interacting with Cloud Firestore.
///
/// The Firecraft class encapsulates common Firestore operations and provides methods for:
/// * Fetching documents and collections
/// * Streaming document and collection changes
/// * Adding, updating, and deleting documents
/// * Pagination support
/// * Batch updates
/// * Document counting
///
/// Example usage:
/// ```dart
/// final firecraft = Firecraft();
///
/// // Fetch a collection
/// final users = await firecraft.fetchCollection(
///   collectionPath: 'users',
///   fromJson: User.fromJson,
/// );
///
/// // Stream document changes
/// firecraft.streamDocument(
///   documentPath: 'users/123',
///   fromJson: User.fromJson,
/// ).listen((user) {
///   print('User updated: ${user?.name}');
/// });
/// ```
class Firecraft {
  /// Creates a new instance of [Firecraft] with the default Firestore instance.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches a list of documents from a collection.
  ///
  /// Parameters:
  /// * [collectionPath] - The path to the collection
  /// * [fromJson] - Function to convert document data to type [T]
  /// * [queryBuilder] - Optional function to build a custom query
  /// * [limit] - Optional limit for the number of documents to fetch
  ///
  /// Returns a [List<T>] containing the fetched documents.
  /// Throws [FirebaseException] if the operation fails.
  Future<List<T>> fetchCollection<T>({
    required String collectionPath,
    required T Function(Map<String, dynamic> json) fromJson,
    Query<Map<String, dynamic>> Function(CollectionReference<Map<String, dynamic>> query)? queryBuilder,
    int? limit,
  }) async {
    try {
      final collectionRef = _firestore.collection(collectionPath);

      var query = queryBuilder != null ? queryBuilder(collectionRef) : collectionRef;

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return fromJson(data);
      }).toList();
    } on FirebaseException catch (_) {
      rethrow;
    }
  }

  /// Fetches a single document from Firestore.
  ///
  /// Parameters:
  /// * [documentPath] - The path to the document
  /// * [fromJson] - Function to convert document data to type [T]
  ///
  /// Returns the document as type [T] or null if it doesn't exist.
  /// Throws [FirebaseException] if the operation fails.
  Future<T?> fetchDocument<T>({
    required String documentPath,
    required T Function(Map<String, dynamic> json) fromJson,
  }) async {
    try {
      final docSnapshot = await _firestore.doc(documentPath).get();

      if (!docSnapshot.exists) {
        return null;
      }

      final data = docSnapshot.data()!;
      data['id'] = docSnapshot.id;
      return fromJson(data);
    } on FirebaseException catch (_) {
      rethrow;
    }
  }

  /// Adds a new document to a collection.
  ///
  /// Parameters:
  /// * [collectionPath] - The path to the collection
  /// * [data] - The document data to add
  ///
  /// Returns a [DocumentReference] for the newly created document.
  /// Throws [FirebaseException] if the operation fails.
  Future<DocumentReference> addDocument({
    required String collectionPath,
    required Map<String, dynamic> data,
  }) async {
    try {
      return await _firestore.collection(collectionPath).add(data);
    } on FirebaseException catch (_) {
      rethrow;
    }
  }

  /// Sets a document's data, creating it if it doesn't exist.
  ///
  /// Parameters:
  /// * [collectionPath] - The path to the collection
  /// * [docId] - The ID of the document
  /// * [data] - The document data to set
  ///
  /// Throws [FirebaseException] if the operation fails.
  Future<void> setDocument({
    required String collectionPath,
    required String docId,
    Map<String, dynamic> data = const <String, dynamic>{},
  }) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).set(data);
    } on FirebaseException catch (_) {
      rethrow;
    }
  }

  /// Updates an existing document's data.
  ///
  /// Parameters:
  /// * [documentPath] - The path to the document
  /// * [data] - The updated field values
  ///
  /// Throws [FirebaseException] if the operation fails.
  Future<void> updateDocument({
    required String documentPath,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.doc(documentPath).update(data);
    } on FirebaseException catch (_) {
      rethrow;
    }
  }

  /// Deletes a document from Firestore.
  ///
  /// Parameters:
  /// * [documentPath] - The path to the document to delete
  ///
  /// Throws [FirebaseException] if the operation fails.
  Future<void> deleteDocument({
    required String documentPath,
  }) async {
    try {
      await _firestore.doc(documentPath).delete();
    } on FirebaseException catch (_) {
      rethrow;
    }
  }

  /// Creates a stream of document changes.
  ///
  /// Parameters:
  /// * [documentPath] - The path to the document
  /// * [fromJson] - Function to convert document data to type [T]
  ///
  /// Returns a [Stream<T?>] that emits updated document data.
  /// Throws [FirebaseException] if the operation fails.
  Stream<T?> streamDocument<T>({
    required String documentPath,
    required T Function(Map<String, dynamic> json) fromJson,
  }) {
    try {
      return _firestore.doc(documentPath).snapshots().map((snapshot) {
        if (!snapshot.exists) {
          return null;
        }

        final data = snapshot.data()!;
        data['id'] = snapshot.id;
        return fromJson(data);
      });
    } on FirebaseException catch (_) {
      rethrow;
    }
  }

  /// Creates a stream of changes to a specific field in a document.
  ///
  /// Parameters:
  /// * [documentPath] - The path to the document
  /// * [key] - The field key to stream
  ///
  /// Returns a [Stream<T?>] that emits the updated field value.
  /// Throws [FirebaseException] if the operation fails.
  Stream<T?> streamDocumentField<T>({
    required String documentPath,
    required String key,
  }) {
    try {
      return _firestore.doc(documentPath).snapshots().map((snapshot) {
        if (!snapshot.exists) {
          return null;
        }

        final data = snapshot.data()!;
        return data[key] as T;
      });
    } on FirebaseException catch (_) {
      rethrow;
    }
  }

  /// Gets a stream of query snapshots for a collection.
  ///
  /// Parameters:
  /// * [collectionPath] - The path to the collection
  /// * [queryBuilder] - Optional function to build a custom query
  ///
  /// Returns a [Stream] of [QuerySnapshot].
  /// Throws [FirebaseException] if the operation fails.
  Stream<QuerySnapshot<Map<String, dynamic>>> getSnapshots({
    required String collectionPath,
    Query<Map<String, dynamic>> Function(CollectionReference<Map<String, dynamic>> query)? queryBuilder,
  }) {
    try {
      final collectionRef = _firestore.collection(collectionPath);
      final query = queryBuilder != null ? queryBuilder(collectionRef) : collectionRef;

      return query.snapshots();
    } on FirebaseException catch (_) {
      rethrow;
    }
  }

  /// Creates a stream of collection changes.
  ///
  /// Parameters:
  /// * [collectionPath] - The path to the collection
  /// * [fromJson] - Function to convert document data to type [T]
  /// * [queryBuilder] - Optional function to build a custom query
  ///
  /// Returns a [Stream<List<T>>] that emits the updated collection data.
  /// Throws [FirebaseException] if the operation fails.
  Stream<List<T>> streamCollection<T>({
    required String collectionPath,
    required T Function(Map<String, dynamic> json) fromJson,
    Query<Map<String, dynamic>> Function(CollectionReference<Map<String, dynamic>> query)? queryBuilder,
  }) {
    try {
      final collectionRef = _firestore.collection(collectionPath);
      final query = queryBuilder != null ? queryBuilder(collectionRef) : collectionRef;

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return fromJson(data);
        }).toList();
      });
    } on FirebaseException catch (_) {
      rethrow;
    }
  }

  /// Updates documents in a collection that match a condition.
  ///
  /// Parameters:
  /// * [collectionPath] - The path to the collection
  /// * [fieldToUpdate] - The field to update in matching documents
  /// * [newValue] - The new value to set
  /// * [condition] - Function that returns true for documents to update
  /// * [queryBuilder] - Optional function to build a custom query
  /// * [batchSize] - Maximum number of documents to update in each batch
  ///
  /// Returns the number of documents updated.
  /// Throws [FirebaseException] if the operation fails.
  Future<int> updateWhereField({
    required String collectionPath,
    required String fieldToUpdate,
    required dynamic newValue,
    required bool Function(Map<String, dynamic> data) condition,
    Query<Map<String, dynamic>> Function(CollectionReference<Map<String, dynamic>> query)? queryBuilder,
    int batchSize = 500, // Firestore limit is 500 writes per batch
  }) async {
    try {
      int updatedCount = 0;

      // Get collection reference
      CollectionReference<Map<String, dynamic>> collectionRef = _firestore.collection(collectionPath);

      // Apply initial query if provided
      Query<Map<String, dynamic>> query = queryBuilder != null ? queryBuilder(collectionRef) : collectionRef;

      // Get all documents that need to be updated
      QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();

      // Filter documents based on condition
      List<DocumentSnapshot<Map<String, dynamic>>> docsToUpdate =
          snapshot.docs.where((doc) => condition(doc.data())).toList();

      // Process in batches
      for (var i = 0; i < docsToUpdate.length; i += batchSize) {
        WriteBatch batch = _firestore.batch();

        // Get current batch of documents
        var currentBatch = docsToUpdate.skip(i).take(batchSize);

        // Add update operations to batch
        for (var doc in currentBatch) {
          batch.update(doc.reference, {fieldToUpdate: newValue});
          updatedCount++;
        }

        // Commit batch
        await batch.commit();
      }

      return updatedCount;
    } on FirebaseException catch (_) {
      rethrow;
    }
  }

  /// Creates a paginated stream of collection data.
  ///
  /// Parameters:
  /// * [collectionPath] - The path to the collection
  /// * [fromJson] - Function to convert document data to type [T]
  /// * [queryBuilder] - Optional function to build a custom query
  /// * [startAfter] - Optional document to start after
  /// * [limit] - Maximum number of documents per page
  ///
  /// Returns a [Stream] of [PaginatedResult<T>].
  /// Throws [FirebaseException] if the operation fails.
  Stream<PaginatedResult<T>> paginatedCollection<T>({
    required String collectionPath,
    required T Function(Map<String, dynamic> json) fromJson,
    Query<Map<String, dynamic>> Function(CollectionReference<Map<String, dynamic>> query)? queryBuilder,
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) {
    try {
      // Start with the collection reference
      CollectionReference<Map<String, dynamic>> collectionRef = _firestore.collection(collectionPath);

      // Apply custom query if provided
      Query<Map<String, dynamic>> query = queryBuilder != null ? queryBuilder(collectionRef) : collectionRef;

      // Apply pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      // Apply limit
      query = query.limit(limit + 1); // Get one extra to check if there's more

      return query.snapshots().map((snapshot) {
        final docs = snapshot.docs;

        // Check if there are more documents
        bool hasMore = docs.length > limit;

        // Remove the extra document if exists
        final items = docs.take(limit).map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return fromJson(data);
        }).toList();

        return PaginatedResult<T>(
          items: items,
          lastDocument: docs.isNotEmpty ? docs[docs.length - 1] : null,
          hasMore: hasMore,
        );
      });
    } on FirebaseException catch (_) {
      rethrow;
    }
  }

  /// Fetches the initial page of a paginated collection.
  ///
  /// Parameters:
  /// * [collectionPath] - The path to the collection
  /// * [fromJson] - Function to convert document data to type [T]
  /// * [queryBuilder] - Optional function to build a custom query
  /// * [limit] - Maximum number of documents per page
  ///
  /// Returns a [PaginatedResult<T>].
  /// Throws [FirebaseException] if the operation fails.
  Future<PaginatedResult<T>> fetchInitialPage<T>({
    required String collectionPath,
    required T Function(Map<String, dynamic> json) fromJson,
    Query<Map<String, dynamic>> Function(CollectionReference<Map<String, dynamic>> query)? queryBuilder,
    int limit = 20,
  }) async {
    try {
      final query = queryBuilder != null
          ? queryBuilder(_firestore.collection(collectionPath))
          : _firestore.collection(collectionPath);

      final snapshots = await query.limit(limit + 1).get();
      final docs = snapshots.docs;

      final hasMore = docs.length > limit;

      final items = docs.take(limit).map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return fromJson(data);
      }).toList();

      return PaginatedResult<T>(
        items: items,
        lastDocument: docs.isNotEmpty ? docs[docs.length - 1] : null,
        hasMore: hasMore,
      );
    } on FirebaseException catch (_) {
      rethrow;
    }
  }

  /// Fetches the next page of a paginated collection.
  ///
  /// Parameters:
  /// * [collectionPath] - The path to the collection
  /// * [fromJson] - Function to convert document data to type [T]
  /// * [lastDocument] - The last document from the previous page
  /// * [queryBuilder] - Optional function to build a custom query
  /// * [limit] - Maximum number of documents per page
  ///
  /// Returns a [PaginatedResult<T>].
  /// Throws [FirebaseException] if the operation fails.
  Future<PaginatedResult<T>> fetchNextPage<T>({
    required String collectionPath,
    required T Function(Map<String, dynamic> json) fromJson,
    required DocumentSnapshot lastDocument,
    Query<Map<String, dynamic>> Function(CollectionReference<Map<String, dynamic>> query)? queryBuilder,
    int limit = 20,
  }) async {
    try {
      var query = queryBuilder != null
          ? queryBuilder(_firestore.collection(collectionPath))
          : _firestore.collection(collectionPath);

      query = query.startAfterDocument(lastDocument).limit(limit + 1);

      final snapshots = await query.get();
      final docs = snapshots.docs;

      final hasMore = docs.length > limit;

      final items = docs.take(limit).map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return fromJson(data);
      }).toList();

      return PaginatedResult<T>(
        items: items,
        lastDocument: docs.isNotEmpty ? docs[docs.length - 1] : null,
        hasMore: hasMore,
      );
    } on FirebaseException catch (_) {
      rethrow;
    }
  }

  /// Creates a stream that emits the count of documents in a collection.
  ///
  /// Parameters:
  /// * [collectionPath] - The path to the collection
  /// * [queryBuilder] - Optional function to build a custom query
  /// * [additionalCondition] - Optional function for additional filtering
  ///
  /// Returns a [Stream<int>] that emits the document count.
  /// Throws [FirebaseException] if the operation fails.
  Stream<int> streamDocumentCount({
    required String collectionPath,
    Query<Map<String, dynamic>> Function(CollectionReference<Map<String, dynamic>> query)? queryBuilder,
    bool Function(Map<String, dynamic> data)? additionalCondition,
  }) {
    try {
      final collectionRef = _firestore.collection(collectionPath);

      final query = queryBuilder != null ? queryBuilder(collectionRef) : collectionRef;

      if (additionalCondition == null) {
        return query.snapshots().map((snapshot) => snapshot.size);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs.where((doc) => additionalCondition(doc.data())).length;
      });
    } on FirebaseException catch (_) {
      rethrow;
    }
  }
}
