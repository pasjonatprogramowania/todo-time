import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_time/domain/entities/task_entity.dart';
import 'package:task_time/presentation/providers/task_usecase_providers.dart';
import 'package:uuid/uuid.dart'; // For generating unique IDs

class TaskFormPage extends ConsumerStatefulWidget {
  final TaskEntity? task; // Task to edit, null if adding new

  const TaskFormPage({super.key, this.task});

  @override
  ConsumerState<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends ConsumerState<TaskFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _timeAwardController; // In minutes

  TaskCategory _selectedCategory = TaskCategory.importantNotUrgent; // Default category
  DateTime? _selectedDueDate;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.task?.name ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _timeAwardController = TextEditingController(
        text: widget.task?.timeAward.inMinutes.toString() ?? '15'); // Default to 15 minutes
    _selectedCategory = widget.task?.category ?? TaskCategory.importantNotUrgent;
    _selectedDueDate = widget.task?.dueDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _timeAwardController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)), // Allow past for flexibility if needed
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)), // Allow up to 2 years in future
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final String name = _nameController.text.trim();
      final String? description = _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null;
      final int timeAwardMinutes = int.tryParse(_timeAwardController.text) ?? 0;

      final taskEntity = TaskEntity(
        id: widget.task?.id ?? const Uuid().v4(),
        name: name,
        description: description,
        category: _selectedCategory,
        timeAward: Duration(minutes: timeAwardMinutes),
        isCompleted: widget.task?.isCompleted ?? false,
        createdAt: widget.task?.createdAt ?? DateTime.now(),
        dueDate: _selectedDueDate,
      );

      try {
        if (_isEditing) {
          await ref.read(updateTaskUseCaseProvider).call(taskEntity);
        } else {
          await ref.read(addTaskUseCaseProvider).call(taskEntity);
        }
        if (mounted) {
          context.pop(); // Go back after saving
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save task: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'Add Task'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _submitForm,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Task Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a task name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description (Optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TaskCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category (Eisenhower Matrix)'),
                items: TaskCategory.values.map((TaskCategory category) {
                  return DropdownMenuItem<TaskCategory>(
                    value: category,
                    child: Text(category.toString().split('.').last), // Simple display name
                  );
                }).toList(),
                onChanged: (TaskCategory? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timeAwardController,
                decoration: const InputDecoration(labelText: 'Time Award (minutes)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter time award';
                  }
                  final int? minutes = int.tryParse(value);
                  if (minutes == null || minutes <= 0) {
                    return 'Please enter a positive number of minutes';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_selectedDueDate == null
                    ? 'No Due Date'
                    : 'Due Date: ${MaterialLocalizations.of(context).formatShortDate(_selectedDueDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDueDate,
                subtitle: _selectedDueDate == null ? const Text('Tap to select a due date') : null,
              ),
               if (_selectedDueDate != null)
                TextButton(
                  child: const Text('Clear Due Date'),
                  onPressed: () {
                    setState(() {
                      _selectedDueDate = null;
                    });
                  },
                ),

              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(_isEditing ? 'Save Changes' : 'Add Task'),
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
