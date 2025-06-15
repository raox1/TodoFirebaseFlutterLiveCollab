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
    if (_formKey.currentState!.validate()) {
      final taskViewModel = Provider.of<TaskViewModel>(context, listen: false);
      await taskViewModel.addTask(
        _titleController.text.trim(),
        _descriptionController.text.trim(),
      );

      if (taskViewModel.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(taskViewModel.errorMessage!)),
        );
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Task'),
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
                    onPressed: taskViewModel.isLoading ? null : _submitTask,
                    child: taskViewModel.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Add Task'),
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