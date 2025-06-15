import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' as drift; // Import drift with alias
import 'package:flutter/material.dart';
import 'package:your_task_app/data/local_database.dart';
import 'package:your_task_app/models/task.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskViewModel with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AppDatabase _localDb;

  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  TaskViewModel(this._localDb) {
    _fetchAndSyncTasks();
  }

  String? get currentUserId => _auth.currentUser?.uid;

  Future<void> _fetchAndSyncTasks() async {
    if (currentUserId == null) {
      await _loadTasksFromLocalDb();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _loadTasksFromLocalDb();

      _firestore
          .collection('tasks')
          .where('collaborators', arrayContains: currentUserId)
          .snapshots()
          .listen((snapshot) async {
        final firestoreTasks = snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();

        for (var task in firestoreTasks) {
          await _localDb.insertTask(LocalTasksCompanion(
            id: drift.Value(task.id),
            title: drift.Value(task.title),
            description: drift.Value(task.description),
            createdBy: drift.Value(task.createdBy),
            collaborators: drift.Value(task.collaborators),
            isCompleted: drift.Value(task.isCompleted),
            createdAt: drift.Value(task.createdAt),
          ));
        }

        final localTaskIds = (await _localDb.getAllTasks()).map((e) => e.id).toSet();
        final firestoreTaskIds = firestoreTasks.map((e) => e.id).toSet();
        final tasksToDelete = localTaskIds.difference(firestoreTaskIds);

        for (var taskId in tasksToDelete) {
          await _localDb.deleteTask(taskId);
        }

        await _loadTasksFromLocalDb();
      });
    } catch (e) {
      _errorMessage = 'Failed to fetch tasks: $e';
      debugPrint('Error fetching and syncing tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadTasksFromLocalDb() async {
    final localDbTasks = await _localDb.getAllTasks();
    _tasks = localDbTasks.map((lt) => Task(
      id: lt.id,
      title: lt.title,
      description: lt.description,
      createdBy: lt.createdBy,
      collaborators: lt.collaborators,
      isCompleted: lt.isCompleted,
      createdAt: lt.createdAt,
    )).toList();
    notifyListeners();
  }

  Future<void> addTask(String title, String description) async {
    if (currentUserId == null) {
      _errorMessage = "User not logged in.";
      notifyListeners();
      return;
    }

    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      final newTask = Task(
        id: '',
        title: title,
        description: description,
        createdBy: currentUserId!,
        collaborators: [currentUserId!],
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('tasks').add(newTask.toFirestore());
      final taskWithId = newTask.copyWith(id: docRef.id);

      await _localDb.insertTask(LocalTasksCompanion(
        id: drift.Value(taskWithId.id),
        title: drift.Value(taskWithId.title),
        description: drift.Value(taskWithId.description),
        createdBy: drift.Value(taskWithId.createdBy),
        collaborators: drift.Value(taskWithId.collaborators),
        isCompleted: drift.Value(taskWithId.isCompleted),
        createdAt: drift.Value(taskWithId.createdAt),
      ));

      await _loadTasksFromLocalDb();
    } catch (e) {
      _errorMessage = 'Failed to add task: $e';
      debugPrint('Error adding task: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

Future<void> updateTaskStatus(Task task, bool isCompleted) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Update Firestore
      await _firestore.collection('tasks').doc(task.id).update({'isCompleted': isCompleted});

      // 2. Update Local DB (Drift)
      // Get the existing task from the local database
      final existingLocalTasks = await (_localDb.select(_localDb.localTasks)
            ..where((tbl) => tbl.id.equals(task.id))) // Use task.id
          .get();

      if (existingLocalTasks.isNotEmpty) {
        final existingLocalTask = existingLocalTasks.first;

        // Create a LocalTasksCompanion using existing values,
        // but with updated isCompleted status
        final updatedCompanion = LocalTasksCompanion(
          id: drift.Value(existingLocalTask.id),
          title: drift.Value(existingLocalTask.title),
          description: drift.Value(existingLocalTask.description),
          createdBy: drift.Value(existingLocalTask.createdBy),
          collaborators: drift.Value(existingLocalTask.collaborators),
          isCompleted: drift.Value(isCompleted), // This is the updated part
          createdAt: drift.Value(existingLocalTask.createdAt),
        );

        await _localDb.updateTask(updatedCompanion);
        await _loadTasksFromLocalDb(); // Reload to reflect local changes
      } else {
        debugPrint('Warning: Local task not found for ID: ${task.id}. Could not update local DB status.');
        // Optionally, if the task is somehow missing locally, you might want to re-add it
        // based on the Firestore data or handle this scenario appropriately.
      }
    } catch (e) {
      _errorMessage = 'Failed to update task status: $e';
      debugPrint('Error updating task status: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCollaborator(String taskId, String collaboratorEmail) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      final collaboratorUserSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: collaboratorEmail)
          .limit(1)
          .get();

      if (collaboratorUserSnapshot.docs.isEmpty) {
        _errorMessage = "Collaborator email not found.";
        return;
      }
      final collaboratorUid = collaboratorUserSnapshot.docs.first.id;

      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) {
        _errorMessage = "Task not found.";
        return;
      }

      List<String> currentCollaborators = List<String>.from(taskDoc['collaborators'] ?? []);
      if (!currentCollaborators.contains(collaboratorUid)) {
        currentCollaborators.add(collaboratorUid);

        await _firestore.collection('tasks').doc(taskId).update({
          'collaborators': FieldValue.arrayUnion([collaboratorUid]),
        });

        final existingLocalTasks = await (_localDb.select(_localDb.localTasks)
              ..where((tbl) => tbl.id.equals(taskId)))
            .get();

        if (existingLocalTasks.isNotEmpty) {
          final existingLocalTask = existingLocalTasks.first;

          final updatedCompanion = LocalTasksCompanion(
            id: drift.Value(existingLocalTask.id),
            title: drift.Value(existingLocalTask.title),
            description: drift.Value(existingLocalTask.description),
            createdBy: drift.Value(existingLocalTask.createdBy),
            collaborators: drift.Value(currentCollaborators),
            isCompleted: drift.Value(existingLocalTask.isCompleted),
            createdAt: drift.Value(existingLocalTask.createdAt),
          );

          await _localDb.updateTask(updatedCompanion);
          await _loadTasksFromLocalDb();
        } else {
          debugPrint('Warning: Local task not found for ID: $taskId. Could not update local DB.');
        }
      } else {
        _errorMessage = "User is already a collaborator.";
      }
    } catch (e) {
      _errorMessage = 'Failed to add collaborator: $e';
      debugPrint('Error adding collaborator: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTaskDetails(String taskId, String newTitle, String newDescription) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Update Firestore
      await _firestore.collection('tasks').doc(taskId).update({
        'title': newTitle,
        'description': newDescription,
      });

      // 2. Update Local DB (Drift)
      final existingLocalTasks = await (_localDb.select(_localDb.localTasks)
            ..where((tbl) => tbl.id.equals(taskId)))
          .get();

      if (existingLocalTasks.isNotEmpty) {
        final existingLocalTask = existingLocalTasks.first;

        final updatedCompanion = LocalTasksCompanion(
          id: drift.Value(existingLocalTask.id),
          title: drift.Value(newTitle), // Updated title
          description: drift.Value(newDescription), // Updated description
          createdBy: drift.Value(existingLocalTask.createdBy),
          collaborators: drift.Value(existingLocalTask.collaborators),
          isCompleted: drift.Value(existingLocalTask.isCompleted),
          createdAt: drift.Value(existingLocalTask.createdAt),
        );

        await _localDb.updateTask(updatedCompanion);
        await _loadTasksFromLocalDb(); // Reload to reflect local changes
      } else {
        debugPrint('Warning: Local task not found for ID: $taskId. Could not update local DB.');
        // If task not found locally, it might be due to a sync issue or race condition.
        // For robustness, you could potentially refetch the specific task from Firestore
        // and insert/replace it locally here.
      }
    } catch (e) {
      _errorMessage = 'Failed to update task: $e';
      debugPrint('Error updating task: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
 
 Future<void> deleteTask(String taskId) async {
    _isLoading = true;
    _errorMessage = null; // Clear previous error
    notifyListeners();

    try {
      // Simulate API call to delete task from your backend
      await Future.delayed(const Duration(seconds: 1));
      // Remove the task from the local list upon successful deletion
      _tasks.removeWhere((task) => task.id == taskId);
    } catch (e) {
      _errorMessage = 'Failed to delete task: $e';
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify listeners whether success or failure
    }
  }
    void clearErrorMessage() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners(); // Notify listeners that the error message has been cleared
    }
  }
}
