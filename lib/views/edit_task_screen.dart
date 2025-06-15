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
    if (_formKey.currentState!.validate()) {
      final taskViewModel = Provider.of<TaskViewModel>(context, listen: false);
      await taskViewModel.updateTaskDetails(
        widget.task.id,
        _titleController.text.trim(),
        _descriptionController.text.trim(),
      );

      if (taskViewModel.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(taskViewModel.errorMessage!)),
        );
      } else {
        // --- REMOVE THE SECOND POP HERE ---
        Navigator.of(context).pop(); // This will correctly take you back to TaskListScreen
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Task Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Consumer<TaskViewModel>(
                builder: (context, taskViewModel, child) {
                  return ElevatedButton(
                    onPressed: taskViewModel.isLoading ? null : _saveChanges,
                    child: taskViewModel.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save Changes'),
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