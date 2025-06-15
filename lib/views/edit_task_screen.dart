import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:your_task_app/models/task.dart';
import 'package:your_task_app/viewmodels/task_viewmodel.dart';

class EditTaskScreen extends StatefulWidget {
  final Task task;

  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current task data
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    // Clear any previous error message before attempting to save
    Provider.of<TaskViewModel>(context, listen: false).clearErrorMessage();

    if (_formKey.currentState!.validate()) {
      final taskViewModel = Provider.of<TaskViewModel>(context, listen: false);

      // IMPORTANT: Ensure your TaskViewModel has an updateTaskDetails method
      // It should take taskId, newTitle, newDescription as parameters
      await taskViewModel.updateTaskDetails(
        widget.task.id,
        _titleController.text.trim(),
        _descriptionController.text.trim(),
      );

      if (taskViewModel.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(taskViewModel.errorMessage!)),
        );
        // Clear the error message after showing it, for consistency
        taskViewModel.clearErrorMessage();
      } else {
        // Pop back to the previous screen (TaskListScreen) on success
        Navigator.of(context).pop();
      }
    }
  }

  // Method to delete task (optional, but often useful for edit screens)
  void _deleteTask() async {
    final taskViewModel = Provider.of<TaskViewModel>(context, listen: false);

    // Show a confirmation dialog before deleting
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${widget.task.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(false); // Do not delete
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.deepOrange)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop(true); // Confirm delete
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, // Red for delete action
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      taskViewModel.clearErrorMessage(); // Clear previous errors
      await taskViewModel.deleteTask(widget.task.id); // Assuming you have this method

      if (taskViewModel.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(taskViewModel.errorMessage!)),
        );
        taskViewModel.clearErrorMessage();
      } else {
        // Pop twice: once for the dialog, once for the EditTaskScreen
        Navigator.of(context).pop(); // Pops the EditTaskScreen
        // If coming from details bottom sheet, you might need another pop
        // Navigator.of(context).pop(); // Example for second pop if needed
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background for the entire screen
      appBar: AppBar(
        title: const Text(
          'Edit Task',
          style: TextStyle(
            color: Colors.black87, // Darker text for app bar title
            fontWeight: FontWeight.bold,
            fontSize: 20, // Adjusted font size
          ),
        ),
        backgroundColor: Colors.white, // White app bar background
        elevation: 0, // Remove app bar shadow
        centerTitle: true, // Center the title
        iconTheme: const IconThemeData(color: Colors.black87), // Darker back arrow
        actions: [
          // Add delete button if the current user created the task
          Consumer<TaskViewModel>(
            builder: (context, taskViewModel, child) {
              if (widget.task.createdBy == taskViewModel.currentUserId) {
                return IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.redAccent), // Red delete icon
                  onPressed: _deleteTask,
                  tooltip: 'Delete Task',
                );
              }
              return const SizedBox.shrink(); // Hide if not owner
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[200], // Subtle bottom border
            height: 1.0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0), // Increased padding for form
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Make changes to your task:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Task Title',
                  hintText: 'e.g., Update project report',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.title, color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Task Description',
                  hintText: 'Provide more details about the task...',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.description, color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
                maxLines: 4,
                validator: (value) {
                  // Make description optional if you prefer, or add a min length
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              Consumer<TaskViewModel>(
                builder: (context, taskViewModel, child) {
                  return SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: taskViewModel.isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: taskViewModel.isLoading
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                          : const Text('Save Changes'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}