import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:your_task_app/models/task.dart';
import 'package:your_task_app/viewmodels/auth_viewmodel.dart';
import 'package:your_task_app/viewmodels/task_viewmodel.dart';
import 'package:your_task_app/views/add_task_screen.dart';
import 'package:your_task_app/views/edit_task_screen.dart'; // Import Edit Screen

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final taskViewModel = Provider.of<TaskViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              authViewModel.signOut();
            },
          ),
        ],
      ),
      body: taskViewModel.isLoading && taskViewModel.tasks.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : taskViewModel.errorMessage != null
              ? Center(child: Text('Error: ${taskViewModel.errorMessage}'))
              : taskViewModel.tasks.isEmpty
                  ? const Center(child: Text('No tasks yet. Add one!'))
                  : ListView.builder(
                      itemCount: taskViewModel.tasks.length,
                      itemBuilder: (context, index) {
                        final task = taskViewModel.tasks[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: ListTile(
                            title: Text(
                              task.title,
                              style: TextStyle(
                                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            subtitle: Text(task.description),
                            trailing: Checkbox(
                              value: task.isCompleted,
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  taskViewModel.updateTaskStatus(task, newValue);
                                }
                              },
                            ),
                            onTap: () {
                              _showTaskDetails(context, task, taskViewModel);
                            },
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddTaskScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showTaskDetails(BuildContext context, Task task, TaskViewModel taskViewModel) {
    final TextEditingController collaboratorController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16.0,
            right: 16.0,
            top: 16.0,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (task.createdBy == taskViewModel.currentUserId)
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.of(context).pop(); // Close bottom sheet
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EditTaskScreen(task: task),
                            ),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  task.description,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text('Created by: ${task.createdBy}'),
                const SizedBox(height: 10),
                Text('Collaborators: ${task.collaborators.join(', ')}'),
                const SizedBox(height: 20),
                if (task.createdBy == taskViewModel.currentUserId)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Add Collaborator (Email):'),
                      TextField(
                        controller: collaboratorController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Enter collaborator email',
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () async {
                          if (collaboratorController.text.isNotEmpty) {
                            await taskViewModel.addCollaborator(task.id, collaboratorController.text.trim());
                            if (taskViewModel.errorMessage != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(taskViewModel.errorMessage!)),
                              );
                            } else {
                              Navigator.of(context).pop();
                            }
                          }
                        },
                        child: const Text('Add Collaborator'),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
