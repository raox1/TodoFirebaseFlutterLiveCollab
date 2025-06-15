import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:your_task_app/viewmodels/task_viewmodel.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitTask() async {
    // Clear any previous error message before attempting to add task
    Provider.of<TaskViewModel>(context, listen: false).clearErrorMessage();

    if (_formKey.currentState!.validate()) {
      final taskViewModel = Provider.of<TaskViewModel>(context, listen: false);
      
      // Show loading indicator in button
      // This is handled by Consumer and taskViewModel.isLoading

      await taskViewModel.addTask(
        _titleController.text.trim(),
        _descriptionController.text.trim(),
      );

      if (taskViewModel.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(taskViewModel.errorMessage!)),
        );
        // It's good practice to clear the error message after showing the snackbar
        // However, if addTask also calls notifyListeners, you might not need an explicit clear
        // Depends on how addTask handles error state internally after failure.
        // For consistency, let's keep the clear just in case.
        taskViewModel.clearErrorMessage(); 
      } else {
        // Only pop if the task was added successfully
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background for the entire screen
      appBar: AppBar(
        title: const Text(
          'Add New Task',
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
                'Enter task details below:',
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
                  hintText: 'e.g., Buy groceries',
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
                  errorBorder: OutlineInputBorder( // Style for error state
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder( // Style for error state when focused
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title for your task.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Task Description (Optional)',
                  hintText: 'e.g., Milk, bread, eggs, apples...',
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
                maxLines: 4, // Allow more lines for description
                // Description can be optional, so no validator by default unless you want to enforce min length
                // validator: (value) {
                //   if (value == null || value.isEmpty) {
                //     return 'Please enter a description.';
                //   }
                //   return null;
                // },
              ),
              const SizedBox(height: 30),
              Consumer<TaskViewModel>(
                builder: (context, taskViewModel, child) {
                  return SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: taskViewModel.isLoading ? null : _submitTask,
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
                          : const Text('Add Task'),
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