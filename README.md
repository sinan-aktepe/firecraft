# Firecraft

A simplified and intuitive wrapper for Cloud Firestore operations in Flutter applications. Firecraft provides an easy-to-use interface for common Firestore operations with built-in pagination support.

## Features

- 🔥 Simple CRUD operations
- 📡 Real-time data streaming
- 📄 Pagination support
- 🔄 Batch updates
- 📊 Document counting
- 🎯 Type-safe operations

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  firecraft: ^0.1.2
```

## Basic Usage

### Initialize Firecraft

```dart
final firecraft = Firecraft();
```

### Fetch Collection Data

```dart
// Define your model
class User {
  final String id;
  final String name;
  final int age;

  User({required this.id, required this.name, required this.age});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      age: json['age'],
    );
  }
}

// Fetch users
final users = await firecraft.fetchCollection(
  collectionPath: 'users',
  fromJson: User.fromJson,
);
```

### Stream Document Changes

```dart
firecraft.streamDocument(
  documentPath: 'users/123',
  fromJson: User.fromJson,
).listen((user) {
  if (user != null) {
    print('User updated: ${user.name}');
  }
});
```

### Add Document

```dart
final docRef = await firecraft.addDocument(
  collectionPath: 'users',
  data: {
    'name': 'John Doe',
    'age': 30,
  },
);
```

### Update Document

```dart
await firecraft.updateDocument(
  documentPath: 'users/123',
  data: {
    'age': 31,
  },
);
```

### Delete Document

```dart
await firecraft.deleteDocument(
  documentPath: 'users/123',
);
```

## Pagination Example

### Initial Page

```dart
PaginatedResult<User> result = await firecraft.fetchInitialPage(
  collectionPath: 'users',
  fromJson: User.fromJson,
  limit: 20,
);

// Display users
for (var user in result.items) {
  print(user.name);
}
```

### Next Page

```dart
if (result.hasMore) {
  final nextPage = await firecraft.fetchNextPage(
    collectionPath: 'users',
    fromJson: User.fromJson,
    lastDocument: result.lastDocument!,
    limit: 20,
  );
  
  // Display next page users
  for (var user in nextPage.items) {
    print(user.name);
  }
}
```

## Stream Paginated Data

```dart
firecraft.paginatedCollection(
  collectionPath: 'users',
  fromJson: User.fromJson,
  limit: 20,
).listen((result) {
  // Handle paginated data updates
  print('Received ${result.items.length} users');
  print('Has more: ${result.hasMore}');
});
```

## Advanced Queries

### Custom Query Builder

```dart
final activeUsers = await firecraft.fetchCollection(
  collectionPath: 'users',
  fromJson: User.fromJson,
  queryBuilder: (query) => query
    .where('status', isEqualTo: 'active')
    .orderBy('lastActive', descending: true),
);
```

### Batch Update Example

```dart
final updatedCount = await firecraft.updateWhereField(
  collectionPath: 'users',
  fieldToUpdate: 'status',
  newValue: 'inactive',
  condition: (data) => data['lastActive'] < DateTime.now().subtract(Duration(days: 30)).millisecondsSinceEpoch,
);

print('Updated $updatedCount users to inactive status');
```

### Document Count Stream

```dart
firecraft.streamDocumentCount(
  collectionPath: 'users',
  queryBuilder: (query) => query.where('status', isEqualTo: 'active'),
).listen((count) {
  print('Active users count: $count');
});
```

## Error Handling

All methods will throw a `FirebaseException` if the operation fails. Always wrap operations in try-catch blocks:

```dart
try {
  final users = await firecraft.fetchCollection(
    collectionPath: 'users',
    fromJson: User.fromJson,
  );
} on FirebaseException catch (e) {
  print('Error fetching users: ${e.message}');
}
```

## Best Practices

1. Always define type-safe models with `fromJson` factories
2. Use appropriate batch sizes for bulk operations (default is 500)
3. Implement proper error handling for all operations
4. Close streams when they're no longer needed
5. Use pagination for large collections
