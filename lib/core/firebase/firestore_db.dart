import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// The project's Firestore database is named `tarlan` (europe, Native mode,
/// Enterprise edition) — NOT `(default). Every repository must go through
/// here; `FirebaseFirestore.instance` alone would hit a nonexistent default.
const String firestoreDatabaseId = 'tarlan';

/// Named-database Firestore handle for the default Firebase app.
FirebaseFirestore tarlanFirestore() => FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: firestoreDatabaseId,
    );
