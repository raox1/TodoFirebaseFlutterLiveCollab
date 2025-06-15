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
      backgroundColor: Colors.white, // Set the background to white
      appBar: AppBar(
        title: const Text(
          'My Tasks',
          style: TextStyle(
            color: Colors.black87, // Darker text for app bar title
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white, // White app bar background
        elevation: 0, // Remove app bar shadow
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.deepOrange), // Eye-catching logout icon
            onPressed: () {
              authViewModel.signOut();
            },
          ),
        ],
        // You can also add a subtle bottom border if you like
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[200],
            height: 1.0,
          ),
        ),
      ),
      body: taskViewModel.isLoading && taskViewModel.tasks.isEmpty
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange)))
          : taskViewModel.errorMessage != null
              ? Center(child: Text('Error: ${taskViewModel.errorMessage}', style: const TextStyle(color: Colors.red)))
              : taskViewModel.tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No tasks yet. Let\'s add some!',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Padding for the list itself
                      itemCount: taskViewModel.tasks.length,
                      itemBuilder: (context, index) {
                        final task = taskViewModel.tasks[index];
                        // Determine card and text colors based on completion status
                        final cardColor = task.isCompleted ? Colors.grey[100] : Colors.white;
                        final titleColor = task.isCompleted ? Colors.grey[500] : Colors.black87;
                        final subtitleColor = task.isCompleted ? Colors.grey[400] : Colors.grey[600];
                        final checkboxColor = task.isCompleted ? Colors.deepOrange : Colors.blueAccent;

                        return Card(
                          color: cardColor, // Apply dynamic card color
                          margin: const EdgeInsets.symmetric(vertical: 8), // Vertical margin between cards
                          elevation: 4, // Add a nice shadow
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12), // Rounded corners for cards
                            side: BorderSide(
                                color: task.isCompleted ? Colors.grey[300]! : Colors.deepOrange.withOpacity(0.2),
                                width: 1), // Subtle border
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0), // Padding inside the card
                            child: ListTile(
                              contentPadding: EdgeInsets.zero, // Remove default ListTile padding
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: titleColor, // Apply dynamic title color
                                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                  decorationColor: Colors.deepOrange, // Color for strikethrough
                                  decorationThickness: 2,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0), // Space between title and subtitle
                                child: Text(
                                  task.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: subtitleColor, // Apply dynamic subtitle color
                                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                    decorationColor: Colors.deepOrange,
                                    decorationThickness: 1.5,
                                  ),
                                ),
                              ),
                              trailing: Checkbox(
                                value: task.isCompleted,
                                onChanged: (newValue) {
                                  if (newValue != null) {
                                    taskViewModel.updateTaskStatus(task, newValue);
                                  }
                                },
                                activeColor: checkboxColor, // Dynamic color for checked checkbox
                                checkColor: Colors.white, // Color of the checkmark
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), // Slightly rounded checkbox
                              ),
                              onTap: () {
                                _showTaskDetails(context, task, taskViewModel);
                              },
                            ),
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
        backgroundColor: Colors.deepOrange, // Vibrant FAB color
        child: const Icon(Icons.add, color: Colors.white), // White icon on FAB
      ),
    );
  }

  void _showTaskDetails(BuildContext context, Task task, TaskViewModel taskViewModel) {
    final TextEditingController collaboratorController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white, // White background for the bottom sheet
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // Rounded top corners
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24.0, // More padding for a cleaner look
            right: 24.0,
            top: 24.0,
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
                        style: const TextStyle(
                          fontSize: 26, // Larger title
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (task.createdBy == taskViewModel.currentUserId)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.deepOrange), // Consistent edit icon color
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
                const SizedBox(height: 12),
                Text(
                  task.description,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]), // Slightly darker description
                ),
                const SizedBox(height: 12),
                Text(
                  'Created by: ${task.createdBy}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                const SizedBox(height: 12),
                Text(
                  'Collaborators: ${task.collaborators.isEmpty ? 'None' : task.collaborators.join(', ')}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                const SizedBox(height: 24),
                if (task.createdBy == taskViewModel.currentUserId)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Collaborator (Email):',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: collaboratorController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Enter collaborator email',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Add Collaborator',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepOrange,
                      side: const BorderSide(color: Colors.deepOrange, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 10), // Extra space at the bottom for aesthetic
              ],
            ),
          ),
        );
      },
    );
  }
}